// Rectangle2DCollisionProfile.cpp — micro-benchmark for Rectangle2D::CheckCollision.
// Run: bin\x64\Release\SGI_Programming_Evaluation.Profile.exe

#include <chrono>
#include <cstdint>
#include <iomanip>
#include <iostream>

#include "Rectangle2D.h"
#include "Rectangle2DCollisionBenchmark.h"

namespace
{
    constexpr std::int64_t kIterations = 1'000'000;

    using Clock = std::chrono::high_resolution_clock;

    double ElapsedMicroseconds(const Clock::time_point start, const Clock::time_point end)
    {
        return std::chrono::duration<double, std::micro>(end - start).count();
    }
}

int main()
{
    const Rectangle2D rect1(0.0f, 0.0f, 10.0f, 10.0f);
    const Rectangle2D rect2(10.0f, 10.0f, 10.0f, 10.0f);

    volatile bool sink = false;

    RunNaiveCollisionBenchmark(rect1, rect2, 10'000, sink);

    const auto start = Clock::now();
    RunNaiveCollisionBenchmark(rect1, rect2, kIterations, sink);
    const auto end = Clock::now();

    const double elapsedUs = ElapsedMicroseconds(start, end);
    const double elapsedMs = elapsedUs / 1000.0;

    std::cout << std::fixed << std::setprecision(3);
    std::cout << "Rectangle2D collision profile\n";
    std::cout << "  Iterations: " << kIterations << '\n';
    std::cout << "  CheckCollision (naive): " << elapsedMs << " ms  (" << elapsedUs << " us)";
    if (elapsedUs > 0.0)
    {
        std::cout << "  [" << std::setprecision(0) << (static_cast<double>(kIterations) / elapsedUs * 1e6)
                  << std::setprecision(3) << " calls/s]";
    }
    std::cout << '\n';

    return 0;
}
