#pragma once

#include <cstdint>

class Rectangle2D;

void RunNaiveCollisionBenchmark(
    const Rectangle2D& rect1,
    const Rectangle2D& rect2,
    std::int64_t iterations,
    volatile bool& sink);
