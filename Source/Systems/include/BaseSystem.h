// BaseSystem.h - Cash Garman Nov-03-2026

#ifndef BASESYSTEM_H
#define BASESYSTEM_H

/// BaseSystem: Per-frame logic driven by entity components.
class BaseSystem
{
public:
    BaseSystem() = default;
    virtual ~BaseSystem();

    BaseSystem(const BaseSystem&) = delete;
    BaseSystem& operator=(const BaseSystem&) = delete;

    /// Run one simulation step (implementations query matching components on entities).
    virtual void Update(float deltaSeconds) = 0;
};

#endif
