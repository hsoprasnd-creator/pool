#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <objc/runtime.h>   // sirf sel_registerName ke liye, isko bhi avoid kar sakte hain but ok

// ImGui headers
#import "imgui.h"
#import "imgui_impl_metal.h"

// Prediction engine
#import "PredictionEngine.hpp"

// KittyMemory se koi direct include nahi, bas original function pointer use karenge

// ------------------------------------------------------------
// Global variables linked from main.mm
// ------------------------------------------------------------
extern double g_liveAimAngle;
extern id g_tableInstance;
extern id g_ballManagerInstance;

// Original function pointer for BallManager::getBallPositionForNumber:
// Yeh main.mm mein global banaya gaya hai (static hataya)
extern CGPoint (*orig_BallManager_getBallPositionForNumber)(id self, SEL _cmd, unsigned int num);

// Static SEL for calling the original method (runtime registered, not @selector)
static SEL sel_getBallPositionForNumber = nil;

// ------------------------------------------------------------
// UI State
// ------------------------------------------------------------
bool menu_Active = false;
bool prediction_Enabled = false;

// ------------------------------------------------------------
// Coordinate transform helper
// ------------------------------------------------------------
ImVec2 WorldToScreen(Vector2D worldPos, CGRect screenBounds) {
    float scaledX = (worldPos.x * (screenBounds.size.width / 800.0f));
    float scaledY = (worldPos.y * (screenBounds.size.height / 500.0f));
    return ImVec2(scaledX, scaledY);
}

// ------------------------------------------------------------
// Trajectory rendering (now uses direct function pointer, no objc_msgSend)
// ------------------------------------------------------------
void RenderChetoLines() {
    if (!prediction_Enabled) return;

    ImDrawList* drawList = ImGui::GetBackgroundDrawList();
    if (!drawList || !g_ballManagerInstance || !g_tableInstance) return;

    // Ensure selector is registered once
    if (!sel_getBallPositionForNumber) {
        sel_getBallPositionForNumber = sel_registerName("getBallPositionForNumber:");
    }

    std::vector<std::pair<int, Vector2D>> activeBalls;
    Vector2D cueBallPos(0, 0);

    // Directly call original function – no @selector, no objc_msgSend
    for (int i = 0; i <= 15; i++) {
        if (g_ballManagerInstance != nil && orig_BallManager_getBallPositionForNumber) {
            CGPoint p = orig_BallManager_getBallPositionForNumber(g_ballManagerInstance, sel_getBallPositionForNumber, i);
            if (p.x != 0.0f || p.y != 0.0f) {
                if (i == 0) {
                    cueBallPos = Vector2D(p.x, p.y);
                } else {
                    activeBalls.push_back({i, Vector2D(p.x, p.y)});
                }
            }
        }
    }

    if (activeBalls.empty()) return; // no balls to predict

    float ballRadius = 10.0f;
    auto lines = BilliardPhysics::CalculateTrajectory(
        cueBallPos,
        (float)g_liveAimAngle,
        100.0f,
        800.0f,
        100.0f,
        500.0f,
        activeBalls,
        5,
        ballRadius
    );

    CGRect screen = [UIScreen mainScreen].bounds;
    for (size_t i = 0; i < lines.size(); i++) {
        ImVec2 p1 = WorldToScreen(lines[i].first, screen);
        ImVec2 p2 = WorldToScreen(lines[i].second, screen);

        drawList->AddLine(p1, p2, IM_COL32(255, 255, 255, 240), 2.5f);
        drawList->AddCircleFilled(p2, 4.0f, IM_COL32(255, 0, 0, 255));
    }
}

// ------------------------------------------------------------
// ImGui Menu
// ------------------------------------------------------------
void DrawMenuInterface() {
    if (!menu_Active) return;

    ImGui::Begin("Mod Menu", &menu_Active, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Text("iOS System Line Prediction Module Controller V2");
    ImGui::Separator();

    ImGui::Checkbox("Enable Prediction Line Vector Draw", &prediction_Enabled);

    if (prediction_Enabled) {
        ImGui::TextColored(ImVec4(0.0f, 1.0f, 0.0f, 1.0f), "System Status: Drawing Core Assets Hooks Active");
        RenderChetoLines();
    } else {
        ImGui::TextColored(ImVec4(1.0f, 0.0f, 0.0f, 1.0f), "System Status: Rendering Suspended Safely (Bypass Mode)");
    }

    ImGui::End();
}
