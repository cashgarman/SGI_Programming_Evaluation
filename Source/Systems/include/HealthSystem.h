// HealthSystem.h - Cash Garman Nov-03-2026

#ifndef HEALTHSYSTEM_H
#define HEALTHSYSTEM_H

#include "BaseSystem.h"

/// HealthSystem: Logic for entities with HealthComponent.
class HealthSystem : public BaseSystem
{
public:
    HealthSystem() = default;
    ~HealthSystem() override = default;

    void Update(float deltaSeconds) override;
};

#endif
