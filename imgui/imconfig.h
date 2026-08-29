//-----------------------------------------------------------------------------
// DEAR IMGUI COMPILE-TIME OPTIONS
// Runtime options (clipboard callbacks, enabling various features, etc.) can generally be set via the ImGuiIO structure.
// You can use ImGui::SetAllocatorFunctions() before calling ImGui::CreateContext() to rewire memory allocation functions.
//-----------------------------------------------------------------------------

#pragma once

//---- Define assertion handler. Defaults to calling assert().
//#define IM_ASSERT(_EXPR)  MyAssert(_EXPR)
//#define IM_ASSERT(_EXPR)  ((void)(_EXPR))     // Disable asserts

//---- Define attributes of all API symbols declarations, e.g. for DLL under Windows
//#define IMGUI_API __declspec(dllexport)
//#define IMGUI_API __declspec(dllimport)

//---- Don't define obsolete functions/enums/names.
#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS
#define IMGUI_DISABLE_OBSOLETE_KEYIO

//---- Disable standard features to save code size
#define IMGUI_DISABLE_DEMO_WINDOWS

//---- Include standard types
#include <stdint.h>
