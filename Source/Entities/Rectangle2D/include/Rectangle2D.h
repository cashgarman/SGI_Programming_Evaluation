// Rectangle2D.h - Cash Garman Nov-02-2026

#ifndef RECTANGLE2D_H
#define RECTANGLE2D_H

#include "Point2D.h"
#include "Entity.h"

/// Rectangle2D: A 2D rectangle defined by its center point and its width and height.
class Rectangle2D : public Entity
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

    public:
        // Constructor
        Rectangle2D(const float x, const float y, const float width, const float height)
            : X(x), Y(y), Width(width), Height(height), center(x, y)
        {
        }
        
        // Destructor
        ~Rectangle2D();
    
        // Copy constructor
        Rectangle2D(const Rectangle2D& other);
        
        // Get the width of the rectangle
        double getWidth() const;
        
        // Get the height of the rectangle
        double getHeight() const;
        
        // Get the center of the rectangle
        Point2D getCenter() const;

        // Check collision with another rectangle
        bool CheckCollision(const Rectangle2D& other) const;
};

#endif