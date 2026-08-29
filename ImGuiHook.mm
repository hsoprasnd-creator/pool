#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <substrate.h>
#import "imgui.h"
#import "imgui_impl_metal.h"
#import "PredictionEngine.hpp"

// Global hooks references
extern double g_liveAimAngle;
extern id g_tableInstance;
extern id g_ballManagerInstance;

typedef struct { float x; float y; float width; float height; } MCRect;
extern MCRect g_tableBounds;

// Menu and Config state
static bool g_imguiInitialized = false;
static bool g_showMenu = true;
static bool g_enableGuidelines = true;
static bool g_colorMatchBall = true;
static int  g_maxBounces = 4;
static float g_lineThickness = 2.5f;

// 8 Ball Pool Color Palette
static const ImU32 kBallColors[16] = {
    IM_COL32(255, 255, 255, 255), // 0: Cue (White)
    IM_COL32(255, 215, 0, 255),   // 1: Yellow
    IM_COL32(0, 122, 255, 255),   // 2: Blue
    IM_COL32(255, 59, 48, 255),   // 3: Red
    IM_COL32(175, 82, 222, 255),  // 4: Purple
    IM_COL32(255, 149, 0, 255),   // 5: Orange
    IM_COL32(52, 199, 89, 255),   // 6: Green
    IM_COL32(162, 132, 94, 255),  // 7: Maroon / Brown
    IM_COL32(30, 30, 30, 255),    // 8: Black
    IM_COL32(255, 215, 0, 255),   // 9: Stripe Yellow
    IM_COL32(0, 122, 255, 255),   // 10: Stripe Blue
    IM_COL32(255, 59, 48, 255),   // 11: Stripe Red
    IM_COL32(175, 82, 222, 255),  // 12: Stripe Purple
    IM_COL32(255, 149, 0, 255),   // 13: Stripe Orange
    IM_COL32(52, 199, 89, 255),   // 14: Stripe Green
    IM_COL32(162, 132, 94, 255)   // 15: Stripe Maroon
};

void RenderChetoImGui() {
    // 1. Mod Menu Box
    if (g_showMenu) {
        ImGui::SetNextWindowSize(ImVec2(300, 210), ImGuiCond_FirstUseEver);
        if (ImGui::Begin("Pool Cheto Menu", &g_showMenu)) {
            ImGui::Checkbox("Enable Guidelines", &g_enableGuidelines);
            ImGui::Checkbox("Color-Match Target Ball", &g_colorMatchBall);
            ImGui::SliderInt("Bounces", &g_maxBounces, 1, 6);
            ImGui::SliderFloat("Thickness", &g_lineThickness, 1.0f, 5.0f);
        }
        ImGui::End();
    }

    if (!g_enableGuidelines || !g_ballManagerInstance || !g_tableInstance) return;

    ImDrawList* drawList = ImGui::GetBackgroundDrawList();
    if (!drawList) return;

    // 2. Fetch Balls
    std::vector<std::pair<int, Vector2D>> activeBalls;
    Vector2D cueBallPos(0, 0);

    for (unsigned int i = 0; i <= 15; i++) {
        CGPoint p = ((CGPoint(*)(id, SEL, unsigned int))objc_msgSend)(g_ballManagerInstance, @selector(getBallPositionForNumber:), i);
        if (p.x != 0.0f || p.y != 0.0f) {
            if (i == 0) cueBallPos = Vector2D(p.x, p.y);
            else activeBalls.push_back({(int)i, Vector2D(p.x, p.y)});
        }
    }

    // 3. Compute Lines
    float minX = g_tableBounds.x;
    float maxX = g_tableBounds.x + g_tableBounds.width;
    float minY = g_tableBounds.y;
    float maxY = g_tableBounds.y + g_tableBounds.height;

    RaycastResult hitResult{};
    auto lines = BilliardPhysics::CalculateTrajectory(cueBallPos, (float)g_liveAimAngle, 
                                                      minX, maxX, minY, maxY, 
                                                      activeBalls, g_maxBounces, &hitResult);

    // 4. Render Lines with Colors
    for (size_t i = 0; i < lines.size(); i++) {
        ImVec2 p1(lines[i].first.x, lines[i].first.y);
        ImVec2 p2(lines[i].second.x, lines[i].second.y);

        ImU32 lineColor = IM_COL32(255, 255, 255, 240); // White Cue Path

        // Target Ball Trajectory
        if (i == lines.size() - 1 && hitResult.hitBall) {
            int hitId = hitResult.hitBallId;
            lineColor = g_colorMatchBall ? kBallColors[hitId % 16] : IM_COL32(0, 255, 0, 255);
            drawList->AddCircleFilled(p1, 5.0f, lineColor); // Target impact spot
        }

        drawList->AddLine(p1, p2, lineColor, g_lineThickness);

        // Wall Bounces
        if (i < lines.size() - 1) {
            drawList->AddCircleFilled(p2, 3.5f, IM_COL32(255, 60, 60, 255));
        }
    }
}

// Metal Hook for Rendering
static void (*orig_MTLCommandBuffer_presentDrawable)(id<MTLCommandBuffer> self, SEL _cmd, id<MTLDrawable> drawable);
static void hook_MTLCommandBuffer_presentDrawable(id<MTLCommandBuffer> self, SEL _cmd, id<MTLDrawable> drawable) {
    if (!g_imguiInitialized && [drawable conformsToProtocol:@protocol(CAMetalDrawable)]) {
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        ImGui::GetIO().DisplaySize = ImVec2(screenSize.width, screenSize.height);
        ImGui_ImplMetal_Init(self.device);
        g_imguiInitialized = true;
    }

    if (g_imguiInitialized) {
        ImGui_ImplMetal_NewFrame(nil);
        ImGui::NewFrame();
        RenderChetoImGui();
        ImGui::Render();
        ImDrawData* drawData = ImGui::GetDrawData();
        if (drawData) {
            // Render ImGui drawData to Metal encoder
        }
    }

    orig_MTLCommandBuffer_presentDrawable(self, _cmd, drawable);
}

void InitImGuiHook() {
    Class MTLCommandBufferClass = objc_getClass("MTLCommandBuffer");
    if (MTLCommandBufferClass) {
        MSHookMessageEx(MTLCommandBufferClass, 
                        @selector(presentDrawable:), 
                        (IMP)hook_MTLCommandBuffer_presentDrawable, 
                        (IMP*)&orig_MTLCommandBuffer_presentDrawable);
    }
}
