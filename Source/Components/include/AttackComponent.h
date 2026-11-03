// AttackComponent.h - Cash Garman Nov-03-2026

#ifndef ATTACKCOMPONENT_H
#define ATTACKCOMPONENT_H

#include "BaseComponent.h"

/// AttackComponent: Offensive power for an entity.
class AttackComponent : public BaseComponent
{
private:
    unsigned int m_attackPower = 0;

public:
    AttackComponent() = default;
    ~AttackComponent() override = default;
};

#endif
