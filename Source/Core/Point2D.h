/// Point2D.h - Cash Garman Nov-02-2026

#ifndef POINT2D_H
#define POINT2D_H

/// Point2D: A 2D point defined by its x and y coordinates.
struct Point2D
{
    public:

    // Coordinates
    float X;
    float Y;

    // Width and height
    float Width;
    float Height;

    // Constructor
    Point2D(double x, double y) : X(x), Y(y), Width(0), Height(0) {};
};

#endif