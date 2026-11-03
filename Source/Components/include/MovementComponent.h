// MovementComponent.h - Cash Garman Nov-03-2026

#ifndef MOVEMENTCOMPONENT_H
#define MOVEMENTCOMPONENT_H

#include "BaseComponent.h"

/// MovementComponent: Travel speed for an entity.
class MovementComponent : public BaseComponent
{
private:
    float m_speed = 0.0f;

public:
    MovementComponent() = default;
    ~MovementComponent() override = default;
};

#endif
