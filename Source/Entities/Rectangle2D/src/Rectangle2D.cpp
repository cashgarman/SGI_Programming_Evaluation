#include "Rectangle2D.h"

#include <cmath>

Rectangle2D::~Rectangle2D() = default;

Rectangle2D::Rectangle2D(const Rectangle2D& other)
    : X(other.X),
      Y(other.Y),
      Width(other.Width),
      Height(other.Height),
      center(other.center)
{
}

double Rectangle2D::getWidth() const
{
    return static_cast<double>(Width);
}

double Rectangle2D::getHeight() const
{
    return static_cast<double>(Height);
}

Point2D Rectangle2D::getCenter() const
{
    return center;
}

bool Rectangle2D::CheckCollision(const Rectangle2D& other) const
{
    const float halfWidthSum = (Width + other.Width) * 0.5f;
    const float halfHeightSum = (Height + other.Height) * 0.5f;

    const float deltaX = std::fabs(X - other.X);
    const float deltaY = std::fabs(Y - other.Y);

    return deltaX <= halfWidthSum && deltaY <= halfHeightSum;
}
