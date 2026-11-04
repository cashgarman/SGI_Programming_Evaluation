#include <doctest/doctest.h>

#include <string>
#include "Rectangle2D.h"

TEST_CASE("Rectangle2D collision detection - naive - true")
{
    // Arrange
    Rectangle2D rect1(0, 0, 10, 10);
    Rectangle2D rect2(10, 10, 10, 10);

    // Act
    const bool collides = rect1.CheckCollision(rect2);

    // Assert
    CHECK(collides);
}

TEST_CASE("Rectangle2D collision detection - naive - false")
{
    // Arrange
    Rectangle2D rect1(0, 0, 10, 10);
    Rectangle2D rect2(20, 20, 10, 10);

    // Act
    const bool collides = rect1.CheckCollision(rect2);

    // Assert
    CHECK(!collides);
}