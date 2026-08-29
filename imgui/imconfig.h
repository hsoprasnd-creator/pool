//-----------------------------------------------------------------------------
// DEAR IMGUI COMPILE-TIME OPTIONS
// Runtime options (clipboard callbacks, enabling various features, etc.) can generally be set via the ImGuiIO structure.
// You can use ImGui::SetAllocatorFunctions() before calling ImGui::CreateContext() to rewire memory allocation functions.
//-----------------------------------------------------------------------------

#pragma once

// ============================================
// FIX: Force C++17 and disable constexpr issues for Objective-C++
// ============================================
#if defined(__OBJC__) || defined(__OBJC_CPP__)
    #define IMGUI_USE_STD_ALGORITHMS
    #define IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    #define IMGUI_DISABLE_DEMO_WINDOWS
#endif

// ============================================
// REST OF YOUR ORIGINAL imconfig.h
// ============================================

//---- Define assertion handler. Defaults to calling assert().
// - If your macro uses multiple statements, make sure is enclosed in a 'do { .. } while (0)' block so it can be used as a single statement.
// - Compiling with NDEBUG will usually strip out assert() to nothing, which is NOT recommended because we use asserts to notify of programmer mistakes.
//#define IM_ASSERT(_EXPR)  MyAssert(_EXPR)
//#define IM_ASSERT(_EXPR)  ((void)(_EXPR))     // Disable asserts

// ... BAQI AAPKI EXISTING imconfig.h CODE ...
