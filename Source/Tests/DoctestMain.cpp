#define DOCTEST_CONFIG_IMPLEMENT
#include <doctest/doctest.h>

int main(int argc, char** argv)
{
    doctest::Context context;

    // Compact by default; use build-and-test.ps1 -VerboseTestOutput or omit -m for banners.
    context.setOption("duration", false);
    context.setOption("order-by", "file");

    context.applyCommandLine(argc, argv);
    return context.run();
}
