#Requires -Version 5.1
<#
.SYNOPSIS
  Builds the Visual Studio solution and runs the doctest test executable.

.EXAMPLE
  .\build-and-test.ps1

.EXAMPLE
  .\build-and-test.ps1 -Configuration Release -Platform x64 -Rebuild
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string] $Configuration = 'Debug',

    [ValidateSet('x64', 'x86')]
    [string] $Platform = 'x64',

    [switch] $Rebuild,
    [switch] $SkipTests,

    # Include every passing CHECK/REQUIRE line in doctest output.
    [switch] $ShowAssertions,

    # Doctest one-line totals only (no compact result table).
    [switch] $MinimalTestOutput,

    # Per-case banners, source locations, and pre-run inventory (legacy verbose).
    [switch] $VerboseTestOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot
$Solution = Join-Path $RepoRoot 'SGI_Programming_Evaluation.sln'

function Get-MsBuildPath {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere) {
        $found = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild `
            -find 'MSBuild\**\Bin\MSBuild.exe' |
            Where-Object { $_ -match '\\Bin\\MSBuild\.exe$' -and $_ -notmatch '\\amd64\\' } |
            Select-Object -First 1
        if ($found) {
            return $found
        }
    }

    $candidates = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }

    throw 'MSBuild.exe not found. Install Visual Studio 2022 (or Build Tools) with the C++ workload.'
}

function Get-DoctestCaseNames {
    param([string] $TestExePath)

    $raw = & $TestExePath -ltc -ni -nv 2>&1
    foreach ($line in $raw) {
        $text = [string]$line
        if ($text -match '^\[doctest\]' -or $text -match '^=+$' -or $text.Trim() -eq '') {
            continue
        }
        $text.Trim()
    }
}

function Get-RepoRelativePath {
    param(
        [string] $Path,
        [string] $RepoRoot
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetFullPath($RepoRoot)
    if (-not $root.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $root += [System.IO.Path]::DirectorySeparatorChar
    }

    if ($full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length) -replace '\\', '/'
    }

    return $full -replace '\\', '/'
}

# VS Code / Cursor terminal links use path:line[:column], not MSVC path(line).
function Format-TerminalSourceLink {
    param(
        [string] $FilePath,
        [int] $Line,
        [string] $RepoRoot,
        [int] $Column = 0
    )

    $relative = Get-RepoRelativePath -Path $FilePath -RepoRoot $RepoRoot
    if ($Column -gt 0) {
        return '{0}:{1}:{2}' -f $relative, $Line, $Column
    }
    return '{0}:{1}' -f $relative, $Line
}

function Format-DoctestOutputLine {
    param(
        [string] $Line,
        [string] $RepoRoot
    )

    if ($Line -match '^(?<path>[A-Za-z]:[^()]+|\S+)\((?<line>\d+)\)(?<suffix>.*)$') {
        $link = Format-TerminalSourceLink -FilePath $Matches.path.Trim() -Line ([int]$Matches.line) -RepoRoot $RepoRoot
        return '{0}{1}' -f $link, $Matches.suffix
    }

    return $Line
}

function Get-DoctestFailures {
    param(
        [string[]] $OutputLines,
        [string] $RepoRoot
    )

    $failures = [System.Collections.Generic.List[object]]::new()
    $currentCase = $null
    $caseLocation = $null
    $pendingCaseLocation = $null

    foreach ($line in $OutputLines) {
        if ($line -match '^(?<path>.+)\((?<line>\d+)\):\s*$') {
            $pendingCaseLocation = Format-TerminalSourceLink -FilePath $Matches.path -Line ([int]$Matches.line) -RepoRoot $RepoRoot
            continue
        }

        if ($line -match '^\s*TEST CASE:\s*(?<name>.+)$') {
            $currentCase = $Matches.name.Trim()
            if ($pendingCaseLocation) {
                $caseLocation = $pendingCaseLocation
                $pendingCaseLocation = $null
            }
            continue
        }

        if ($line -match '^(?<path>.+)\((?<line>\d+)\):\s*ERROR:\s*(?<message>.+)$') {
            $assertLocation = Format-TerminalSourceLink -FilePath $Matches.path -Line ([int]$Matches.line) -RepoRoot $RepoRoot
            $failures.Add([pscustomobject]@{
                    CaseName         = $currentCase
                    CaseLocation     = $caseLocation
                    AssertionLocation = $assertLocation
                    Message          = $Matches.message.Trim()
                })
        }
    }

    return $failures
}

function Get-DoctestRunStats {
    param([string[]] $OutputLines)

    $stats = @{
        cases             = 0
        passed            = 0
        failed            = 0
        skipped           = 0
        assertions        = 0
        assertionsPassed  = 0
        assertionsFailed  = 0
        status            = ''
    }

    foreach ($line in $OutputLines) {
        if ($line -match '^\[doctest\] test cases: (\d+) \| (\d+) passed \| (\d+) failed \| (\d+) skipped') {
            $stats.cases = [int]$Matches[1]
            $stats.passed = [int]$Matches[2]
            $stats.failed = [int]$Matches[3]
            $stats.skipped = [int]$Matches[4]
        }
        elseif ($line -match '^\[doctest\] assertions: (\d+) \| (\d+) passed \| (\d+) failed') {
            $stats.assertions = [int]$Matches[1]
            $stats.assertionsPassed = [int]$Matches[2]
            $stats.assertionsFailed = [int]$Matches[3]
        }
        elseif ($line -match '^\[doctest\] Status: (.+)$') {
            $stats.status = $Matches[1].Trim()
        }
    }

    return $stats
}

function Get-FailureLinkByCaseName {
    param([object[]] $Failures)

    $links = @{}
    foreach ($failure in $Failures) {
        $name = [string]$failure.CaseName
        if (-not $name -or $links.ContainsKey($name)) {
            continue
        }

        $link = if ($failure.AssertionLocation) { $failure.AssertionLocation } else { $failure.CaseLocation }
        if ($link) {
            $links[$name] = $link
        }
    }

    return $links
}

function Write-CompactTestSummary {
    param(
        [string[]] $CaseNames,
        [hashtable] $Stats,
        [int] $ExitCode,
        [object[]] $Failures = @()
    )

    $failureLinks = Get-FailureLinkByCaseName -Failures $Failures
    $failedCaseNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($failure in $Failures) {
        if ($failure.CaseName) {
            [void]$failedCaseNames.Add([string]$failure.CaseName)
        }
    }

    $total = if ($Stats.cases -gt 0) { $Stats.cases } else { $CaseNames.Count }
    $passed = $Stats.passed
    $failed = $Stats.failed
    $assertions = $Stats.assertionsPassed

    if ($ExitCode -eq 0) {
        Write-Host ("Tests: {0}/{1} passed, {2} assertions OK" -f $passed, $total, $assertions) -ForegroundColor Green
    }
    else {
        Write-Host ("Tests: {0}/{1} passed, {2} failed, {3} assertion failures" -f `
                $passed, $total, $failed, $Stats.assertionsFailed) -ForegroundColor Red
    }

    for ($i = 0; $i -lt $CaseNames.Count; $i++) {
        $name = $CaseNames[$i]
        $isFailed = $failedCaseNames.Contains([string]$name)
        if ($ExitCode -eq 0) {
            $mark = 'ok'
        }
        elseif ($failedCaseNames.Count -gt 0) {
            $mark = if ($isFailed) { 'FAIL' } else { 'ok' }
        }
        else {
            $mark = 'FAIL'
        }

        $line = "  [{0}] {1}" -f $mark, $name
        if ($mark -eq 'FAIL' -and $failureLinks.ContainsKey([string]$name)) {
            $line = '{0}  {1}' -f $line, $failureLinks[[string]$name]
        }
        Write-Host $line
    }

    if ($ExitCode -ne 0 -and $Stats.status) {
        Write-Host ("  -> {0}" -f $Stats.status) -ForegroundColor Red
    }
}

function Write-DoctestOutput {
    param(
        [string[]] $OutputLines,
        [string] $RepoRoot
    )

    foreach ($line in $OutputLines) {
        Write-Host (Format-DoctestOutputLine -Line $line -RepoRoot $RepoRoot)
    }
}

function Write-FailedTestLinkList {
    param([object[]] $Failures)

    if ($Failures.Count -eq 0) {
        return
    }

    Write-Host ''
    Write-Host 'Failed test links (Ctrl+click):' -ForegroundColor Red
    foreach ($failure in $Failures) {
        $link = if ($failure.AssertionLocation) { $failure.AssertionLocation } else { $failure.CaseLocation }
        if (-not $link) {
            continue
        }

        $label = [string]$failure.CaseName
        if ($label) {
            Write-Host ('  {0}  {1}' -f $link, $label)
        }
        else {
            Write-Host ('  {0}' -f $link)
        }
    }
}

if (-not (Test-Path -LiteralPath $Solution)) {
    throw "Solution not found: $Solution"
}

$msbuild = Get-MsBuildPath
$buildTarget = if ($Rebuild) { 'Rebuild' } else { 'Build' }
$binPlatform = if ($Platform -eq 'x86') { 'Win32' } else { 'x64' }
$testExe = Join-Path $RepoRoot "bin\$binPlatform\$Configuration\SGI_Programming_Evaluation.Tests.exe"

Write-Host "MSBuild:       $msbuild"
Write-Host "Solution:      $Solution"
Write-Host "Configuration: $Configuration"
Write-Host "Platform:      $Platform (output under bin\$binPlatform\)"
Write-Host "Target:        $buildTarget"
Write-Host ''

& $msbuild $Solution `
    "/t:$buildTarget" `
    "/p:Configuration=$Configuration" `
    "/p:Platform=$Platform" `
    /m `
    /v:minimal

if ($LASTEXITCODE -ne 0) {
    throw "MSBuild failed with exit code $LASTEXITCODE"
}

if ($SkipTests) {
    Write-Host 'Build succeeded (tests skipped).'
    exit 0
}

if (-not (Test-Path -LiteralPath $testExe)) {
    throw "Test executable not found after build: $testExe"
}

Write-Host ''
Write-Host "Running tests: $testExe"

$caseNames = @(Get-DoctestCaseNames -TestExePath $testExe)

$testArgs = @('-ni', '-nv')
if ($MinimalTestOutput) {
    $testArgs += '-m'
}
if ($ShowAssertions) {
    $testArgs += '-s'
}

$testOutput = @(& $testExe @testArgs 2>&1 | ForEach-Object { [string]$_ })
$testExit = $LASTEXITCODE
$stats = Get-DoctestRunStats -OutputLines $testOutput
$failures = @(Get-DoctestFailures -OutputLines $testOutput -RepoRoot $RepoRoot)

if ($stats.cases -eq 0 -and $caseNames.Count -gt 0) {
    $stats.cases = $caseNames.Count
    if ($testExit -eq 0) {
        $stats.passed = $caseNames.Count
    }
}

$verboseFailureOutput = @()
if ($testExit -ne 0 -and $failures.Count -eq 0) {
    $verboseFailureOutput = @(& $testExe -ni -nv 2>&1 | ForEach-Object { [string]$_ })
    $failures = @(Get-DoctestFailures -OutputLines $verboseFailureOutput -RepoRoot $RepoRoot)
}

Write-Host ''
if ($VerboseTestOutput) {
    Write-DoctestOutput -OutputLines $testOutput -RepoRoot $RepoRoot
}
elseif (-not $MinimalTestOutput) {
    Write-CompactTestSummary -CaseNames $caseNames -Stats $stats -ExitCode $testExit -Failures $failures
}
else {
    if ($testOutput.Count -gt 0) {
        Write-DoctestOutput -OutputLines $testOutput -RepoRoot $RepoRoot
    }
    Write-CompactTestSummary -CaseNames $caseNames -Stats $stats -ExitCode $testExit -Failures $failures
}

if ($testExit -ne 0) {
    if (-not $VerboseTestOutput) {
        Write-Host ''
        Write-Host 'Failure details (verbose rerun):'
        if ($verboseFailureOutput.Count -eq 0) {
            $verboseFailureOutput = @(& $testExe -ni -nv 2>&1 | ForEach-Object { [string]$_ })
        }
        Write-DoctestOutput -OutputLines $verboseFailureOutput -RepoRoot $RepoRoot
    }
    elseif ($failures.Count -eq 0) {
        $failures = @(Get-DoctestFailures -OutputLines $testOutput -RepoRoot $RepoRoot)
    }

    Write-FailedTestLinkList -Failures $failures
    Write-Host ''
    Write-Error "Tests failed with exit code $testExit"
    exit $testExit
}

Write-Host ''
Write-Host 'Build and tests succeeded.'
exit 0
