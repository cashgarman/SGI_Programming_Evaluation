// AttackSystem.h - Cash Garman Nov-03-2026

#ifndef ATTACKSYSTEM_H
#define ATTACKSYSTEM_H

#include "BaseSystem.h"

/// AttackSystem: Logic for entities with AttackComponent.
class AttackSystem : public BaseSystem
{
public:
    AttackSystem() = default;
    ~AttackSystem() override = default;

    void Update(float deltaSeconds) override;
};

#endif
