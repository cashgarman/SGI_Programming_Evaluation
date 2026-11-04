// Rectangle2D.h - Cash Garman Nov-02-2026

#ifndef RECTANGLE2D_H
#define RECTANGLE2D_H

#include "Point2D.h"

/// Rectangle2D: A 2D rectangle defined by its center point and its width and height.
class Rectangle2D
{
    private:
        // Coordinates
        float X;
        float Y;

        // Width and height
        float Width;
        float Height;

        // Center point
        Point2D center;

        // Bounding box
        Rectangle2D BoundingBox;

    public:
        Rectangle2D(const float x, const float y, const float width, const float height);

        // Check for collision with another rectangle using the naive approach
        bool CheckCollision(const Rectangle2D& other) const;

        // Calculate the bounding box of the rectangle
        Rectangle2D CalculateBoundingBox() const;
};

#endif
