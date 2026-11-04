// Entity.h - Cash Garman Nov-03-2026

#ifndef ENTITY_H
#define ENTITY_H

#include "BaseEntity.h"

/// Entity: 2D object with axis-aligned bounds (center x/y, width, height).
class Entity : public BaseEntity
{
private:
    float X;
    float Y;
    float Width;
    float Height;

    // Cached half
    float HalfWidth;
    float HalfHeight;

public:
    Entity(float x, float y, float width, float height);

    Entity(const Entity&) = default;
    Entity& operator=(const Entity&) = default;

    float GetX() const { return X; }
    float GetY() const { return Y; }
    float GetWidth() const { return Width; }
    float GetHeight() const { return Height; }
    float GetHalfWidth() const { return HalfWidth; }
    float GetHalfHeight() const { return HalfHeight; }


};

#endif
