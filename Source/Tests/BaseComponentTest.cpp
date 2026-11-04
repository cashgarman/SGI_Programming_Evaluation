#include <doctest/doctest.h>

#include <type_traits>

#include "BaseComponent.h"

TEST_CASE("BaseComponent cannot be instantiated")
{
    CHECK(std::is_abstract_v<BaseComponent>);
    CHECK_FALSE(std::is_constructible_v<BaseComponent>);
}