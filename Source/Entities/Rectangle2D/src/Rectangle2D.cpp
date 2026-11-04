#include <cmath>
#include "Rectangle2D.h"

/**
 * @brief Constructor for the Rectangle2D class
 * @param x The x coordinate of the center of the rectangle
 * @param y The y coordinate of the center of the rectangle
 * @param width The width of the rectangle
 * @param height The height of the rectangle
 */
Rectangle2D::Rectangle2D(const float x, const float y, const float width, const float height)
    : X(x), Y(y), Width(width), Height(height), center(x, y)
{
}

/**
 * @brief Check for collision with another rectangle using the naive approach
 * @param other The other rectangle to check collision with
 * @return True if the rectangles are colliding, false otherwise
 */
bool Rectangle2D::CheckCollision(const Rectangle2D& other) const
{
    return X + Width >= other.X && other.X + other.Width >= X &&
           Y + Height >= other.Y && other.Y + other.Height >= Y;
}

/**
 * @brief Calculate the bounding box of the rectangle
 * @return The bounding box of the rectangle
 */
Rectangle2D Rectangle2D::CalculateBoundingBox() const
{
    return Rectangle2D(X - Width * 0.5f, Y - Height * 0.5f, Width, Height);
}