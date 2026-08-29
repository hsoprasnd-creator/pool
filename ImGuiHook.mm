#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <substrate.h>
#import <objc/message.h>
#import "imgui.h"
#import "imgui_impl_metal.h"
#import "PredictionEngine.hpp"

// External references linked across modules runtime system mapping
extern double g_liveAimAngle;
extern id g_tableInstance;
extern id g_ballManagerInstance;

// State control synchronization flags variables mappings
bool menu_Active = false; 
bool prediction_Enabled = false;

// Interface system conversion vectors parameters
ImVec2 WorldToScreen(Vector2D worldPos, CGRect screenBounds) {
    // Basic scaling logic mapping coordinate spaces configuration points matrix
    float scaledX = (worldPos.x * (screenBounds.size.width / 800.0f));
    float scaledY = (worldPos.y * (screenBounds.size.height / 500.0f));
    return ImVec2(scaledX, scaledY); 
}

// Trajectory pipeline computations engine handler logic module loops 
void RenderChetoLines() {
    // SECURITY VALIDATION: Exits process processing loops if global parameters are not completely ready
    if (!prediction_Enabled) return;

    ImDrawList* drawList = ImGui::GetBackgroundDrawList();
    if (!drawList || !g_ballManagerInstance || !g_tableInstance) return;

    std::vector<std::pair<int, Vector2D>> activeBalls;
    Vector2D cueBallPos(0, 0);

    // CRASH CONTROL PATTERN: Encapsulates runtime messaging strings inside strict exceptions processing layer
    @try {
        for (int i = 0; i <= 15; i++) {
            // Verify structure state parameters definitions safety validation rules mapping triggers
            if (g_ballManagerInstance != nil && [g_ballManagerInstance respondsToSelector:@selector(getBallPositionForNumber:)]) {
                
                // Using precise programmatic explicit signature calls matrix interfaces patterns
                CGPoint p = ((CGPoint(*)(id, SEL, unsigned int))objc_msgSend)(g_ballManagerInstance, @selector(getBallPositionForNumber:), i);
                
                if (p.x != 0.0f || p.y != 0.0f) {
                    if (i == 0) {
                        cueBallPos = Vector2D(p.x, p.y);
                    } else {
                        activeBalls.push_back({i, Vector2D(p.x, p.y)});
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        // Suppresses scanning interception signatures anomalies tracking blocks
        return; 
    }

    // Trajectory calculations algorithm setup passing structures pointers arrays
    auto lines = BilliardPhysics::CalculateTrajectory(cueBallPos, (float)g_liveAimAngle, 
                                                      100.0f, 800.0f, 100.0f, 500.0f, 
                                                      activeBalls, 5);

    // Interface canvas vector execution loops iterations processing layer
    CGRect screen = [UIScreen mainScreen].bounds;
    for (size_t i = 0; i < lines.size(); i++) {
        ImVec2 p1 = WorldToScreen(lines[i].first, screen);
        ImVec2 p2 = WorldToScreen(lines[i].second, screen);

        // Core line geometry properties vectors definition configuration profiles
        drawList->AddLine(p1, p2, IM_COL32(255, 255, 255, 240), 2.5f);
        drawList->AddCircleFilled(p2, 4.0f, IM_COL32(255, 0, 0, 255));
    }
}

// Main operational graphical control canvas display layer layouts interface execution systems
void DrawMenuInterface() {
    if (!menu_Active) return;

    // Standard structural configurations parameters layout setups UI panel
    ImGui::Begin("Mod Menu", &menu_Active, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Text("iOS System Line Prediction Module Controller V2");
    ImGui::Separator();
    
    // Interactive variables linkages mappings switches toggles
    ImGui::Checkbox("Enable Prediction Line Vector Draw", &prediction_Enabled);
    
    // Execution loops logic elements mapping interfaces
    if (prediction_Enabled) {
        ImGui::TextColored(ImVec4(0.0f, 1.0f, 0.0f, 1.0f), "System Status: Drawing Core Assets Hooks Active");
        RenderChetoLines();
    } else {
        ImGui::TextColored(ImVec4(1.0f, 0.0f, 0.0f, 1.0f), "System Status: Rendering Suspended Safely (Bypass Mode)");
    }
    
    ImGui::End();
}
