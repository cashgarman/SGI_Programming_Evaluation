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

function Write-CompactTestSummary {
    param(
        [string[]] $CaseNames,
        [hashtable] $Stats,
        [int] $ExitCode
    )

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
        $mark = if ($ExitCode -eq 0) { 'ok' } else { 'FAIL' }
        Write-Host ("  [{0}] {1}" -f $mark, $CaseNames[$i])
    }

    if ($ExitCode -ne 0 -and $Stats.status) {
        Write-Host ("  -> {0}" -f $Stats.status) -ForegroundColor Red
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

if ($stats.cases -eq 0 -and $caseNames.Count -gt 0) {
    $stats.cases = $caseNames.Count
    if ($testExit -eq 0) {
        $stats.passed = $caseNames.Count
    }
}

Write-Host ''
if ($VerboseTestOutput) {
    $testOutput | ForEach-Object { Write-Host $_ }
}
elseif (-not $MinimalTestOutput) {
    Write-CompactTestSummary -CaseNames $caseNames -Stats $stats -ExitCode $testExit
}
else {
    if ($testOutput.Count -gt 0) {
        $testOutput | ForEach-Object { Write-Host $_ }
    }
    Write-CompactTestSummary -CaseNames $caseNames -Stats $stats -ExitCode $testExit
}

if ($testExit -ne 0) {
    if (-not $VerboseTestOutput) {
        Write-Host ''
        Write-Host 'Failure details (verbose rerun):'
        & $testExe -ni -nv
    }
    Write-Host ''
    Write-Error "Tests failed with exit code $testExit"
    exit $testExit
}

Write-Host ''
Write-Host 'Build and tests succeeded.'
exit 0
