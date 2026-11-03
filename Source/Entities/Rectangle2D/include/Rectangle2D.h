// Rectangle2D.h - Cash Garman Nov-02-2026

#ifndef RECTANGLE2D_H
#define RECTANGLE2D_H

/// Rectangle2D: A 2D rectangle defined by its center point and its width and height.
class Rectangle2D : Entity
{
    public:
        // Coordinates
        float X;
        float Y;

        // Width and height
        float Width;
        float Height;

        // Constructor
        Rectangle2D(const Point2D& center, double width, double height);
        
        // Destructor
        ~Rectangle2D();
        
        // Get the width of the rectangle
        double getWidth() const;
        
        // Get the height of the rectangle
        double getHeight() const;
        
        // Get the center of the rectangle
        Point2D getCenter() const;

        // Check collision with another rectangle
        bool checkCollision(const Rectangle2D& other) const;
};


#endif