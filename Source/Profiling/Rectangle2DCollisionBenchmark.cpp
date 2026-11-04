#include <cstdint>

#include "Rectangle2D.h"

#if defined(_MSC_VER)
#define PROFILE_NOINLINE __declspec(noinline)
#else
#define PROFILE_NOINLINE __attribute__((noinline))
#endif

PROFILE_NOINLINE bool InvokeNaiveCollision(const Rectangle2D& a, const Rectangle2D& b)
{
    return a.CheckCollision(b);
}

void RunNaiveCollisionBenchmark(
    const Rectangle2D& rect1,
    const Rectangle2D& rect2,
    const std::int64_t iterations,
    volatile bool& sink)
{
    for (std::int64_t i = 0; i < iterations; ++i)
    {
        sink ^= InvokeNaiveCollision(rect1, rect2);
    }
}
