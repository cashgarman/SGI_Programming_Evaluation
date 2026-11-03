// BaseComponent.h - Cash Garman Nov-03-2026

#ifndef BASECOMPONENT_H
#define BASECOMPONENT_H

/// BaseComponent: Polymorphic component type stored on entities.
class BaseComponent
{
public:
    BaseComponent() = default;
    virtual ~BaseComponent() = 0; // Abstract — not instantiable

    BaseComponent(const BaseComponent&) = default;
    BaseComponent& operator=(const BaseComponent&) = default;
};

#endif
