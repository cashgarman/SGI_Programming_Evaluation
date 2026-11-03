// HealthComponent.h - Cash Garman Nov-03-2026

#ifndef HEALTHCOMPONENT_H
#define HEALTHCOMPONENT_H

#include "BaseComponent.h"

/// HealthComponent: Hit points for an entity.
class HealthComponent : public BaseComponent
{
private:
    int m_health = 0;

public:
    HealthComponent() = default;
    ~HealthComponent() override = default;
};

#endif
