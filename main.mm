#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// Safe Global references
double g_liveAimAngle = 0.0;
id __weak g_tableInstance = nil;
id __weak g_ballManagerInstance = nil;

typedef struct { float x; float y; float width; float height; } MCRect;
MCRect g_tableBounds = {100.0f, 100.0f, 700.0f, 400.0f};

// 1. Safe Hook AimAngle
static void (*orig_VisualCue_setAimAngle)(id self, SEL _cmd, void *mcNumberPtr);
static void hook_VisualCue_setAimAngle(id self, SEL _cmd, void *mcNumberPtr) {
    if (mcNumberPtr != NULL) {
        g_liveAimAngle = *(double *)mcNumberPtr;
    }
    orig_VisualCue_setAimAngle(self, _cmd, mcNumberPtr);
}

// 2. Safe Hook BallManager
static CGPoint (*orig_BallManager_getBallPositionForNumber)(id self, SEL _cmd, unsigned int num);
static CGPoint hook_BallManager_getBallPositionForNumber(id self, SEL _cmd, unsigned int num) {
    if (self) {
        g_ballManagerInstance = self;
    }
    return orig_BallManager_getBallPositionForNumber(self, _cmd, num);
}

// 3. Safe Hook Table Bounds
static MCRect (*orig_Table_tableBounds)(id self, SEL _cmd);
static MCRect hook_Table_tableBounds(id self, SEL _cmd) {
    if (self) {
        g_tableInstance = self;
        g_tableBounds = orig_Table_tableBounds(self, _cmd);
    }
    return g_tableBounds;
}

// External hook from ImGuiHook.mm
extern void InitImGuiHook();

// Constructor with Safe Class Checking
__attribute__((constructor))
static void InitPoolDylib() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class VisualCueClass = objc_getClass("VisualCue");
        if (VisualCueClass) {
            MSHookMessageEx(VisualCueClass, @selector(setAimAngle:), (IMP)hook_VisualCue_setAimAngle, (IMP*)&orig_VisualCue_setAimAngle);
        }

        Class BallManagerClass = objc_getClass("BallManager");
        if (BallManagerClass) {
            MSHookMessageEx(BallManagerClass, @selector(getBallPositionForNumber:), (IMP)hook_BallManager_getBallPositionForNumber, (IMP*)&orig_BallManager_getBallPositionForNumber);
        }

        Class TableClass = objc_getClass("Table");
        if (TableClass) {
            MSHookMessageEx(TableClass, @selector(tableBounds), (IMP)hook_Table_tableBounds, (IMP*)&orig_Table_tableBounds);
        }

        InitImGuiHook();
    });
}
