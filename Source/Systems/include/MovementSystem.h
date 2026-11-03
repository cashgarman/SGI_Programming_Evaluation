// MovementSystem.h - Cash Garman Nov-03-2026

#ifndef MOVEMENTSYSTEM_H
#define MOVEMENTSYSTEM_H

#include "BaseSystem.h"

/// MovementSystem: Logic for entities with MovementComponent.
class MovementSystem : public BaseSystem
{
public:
    MovementSystem() = default;
    ~MovementSystem() override = default;

    void Update(float deltaSeconds) override;
};

#endif
