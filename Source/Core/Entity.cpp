#include "Entity.h"

Entity::Entity(float x, float y, float width, float height)
    : X(x),
      Y(y),
      Width(width),
      Height(height),
      HalfWidth(width * 0.5f),
      HalfHeight(height * 0.5f)
{
}
