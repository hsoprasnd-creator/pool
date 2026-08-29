#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <substrate.h>
#import "imgui.h"
#import "imgui_impl_metal.h"
#import "PredictionEngine.hpp"

// Global game data references (Pichle steps se)
extern double g_liveAimAngle;
extern id g_tableInstance;
extern id g_ballManagerInstance;

// World Coordinates to Screen Pixels converter
ImVec2 WorldToScreen(Vector2D worldPos, CGRect screenBounds) {
    // Screen aspect ratio aur game scaling ke mutabiq map karein
    return ImVec2(worldPos.x, worldPos.y); 
}

// ImGui Render Function
void RenderChetoLines() {
    ImDrawList* drawList = ImGui::GetBackgroundDrawList();
    if (!drawList || !g_ballManagerInstance || !g_tableInstance) return;

    // 1. Fetch live Balls from BallManager
    std::vector<std::pair<int, Vector2D>> activeBalls;
    Vector2D cueBallPos(0, 0);

    for (int i = 0; i <= 15; i++) {
        // [BallManager getBallPositionForNumber:] call
        CGPoint p = ((CGPoint(*)(id, SEL, unsigned int))objc_msgSend)(g_ballManagerInstance, @selector(getBallPositionForNumber:), i);
        if (p.x != 0.0f || p.y != 0.0f) {
            if (i == 0) {
                cueBallPos = Vector2D(p.x, p.y);
            } else {
                activeBalls.push_back({i, Vector2D(p.x, p.y)});
            }
        }
    }

    // 2. Fetch Table Bounds
    // [Table tableBounds] call
    // float minX = 100.0f, maxX = 800.0f, minY = 100.0f, maxY = 500.0f;

    // 3. Multi-Bounce Trajectory Calculate karein
    auto lines = BilliardPhysics::CalculateTrajectory(cueBallPos, (float)g_liveAimAngle, 
                                                      100.0f, 800.0f, 100.0f, 500.0f, 
                                                      activeBalls, 5);

    // 4. Draw Lines on Screen
    CGRect screen = [UIScreen mainScreen].bounds;
    for (size_t i = 0; i < lines.size(); i++) {
        ImVec2 p1 = WorldToScreen(lines[i].first, screen);
        ImVec2 p2 = WorldToScreen(lines[i].second, screen);

        // White Line with 2.0f thickness
        drawList->AddLine(p1, p2, IM_COL32(255, 255, 255, 240), 2.5f);
        
        // Bounce point par circle
        drawList->AddCircleFilled(p2, 4.0f, IM_COL32(255, 0, 0, 255));
    }
}