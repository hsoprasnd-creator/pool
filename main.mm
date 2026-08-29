#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <substrate.h>

// Global variables export (Prediction Engine ke liye)
double g_liveAimAngle = 0.0;
id g_tableInstance = nil;
id g_ballManagerInstance = nil;

// 1. Hook VisualCue setAimAngle:
static void (*orig_VisualCue_setAimAngle)(id self, SEL _cmd, void *mcNumberPtr);
static void hook_VisualCue_setAimAngle(id self, SEL _cmd, void *mcNumberPtr) {
    if (mcNumberPtr) {
        g_liveAimAngle = *(double *)mcNumberPtr;
    }
    orig_VisualCue_setAimAngle(self, _cmd, mcNumberPtr);
}

// 2. Hook BallManager getBallPositionForNumber:
static CGPoint (*orig_BallManager_getBallPositionForNumber)(id self, SEL _cmd, unsigned int num);
static CGPoint hook_BallManager_getBallPositionForNumber(id self, SEL _cmd, unsigned int num) {
    g_ballManagerInstance = self;
    return orig_BallManager_getBallPositionForNumber(self, _cmd, num);
}

// 3. Hook Table tableBounds
typedef struct { float x; float y; float width; float height; } MCRect;
static MCRect (*orig_Table_tableBounds)(id self, SEL _cmd);
static MCRect hook_Table_tableBounds(id self, SEL _cmd) {
    g_tableInstance = self;
    return orig_Table_tableBounds(self, _cmd);
}

// 4. Initialize All Hooks on Dylib Load
__attribute__((constructor))
static void InitPoolDylib() {
    NSLog(@"[PoolPrediction] Dylib Injected Successfully!");

    // VisualCue Hook
    Class VisualCueClass = objc_getClass("VisualCue");
    if (VisualCueClass) {
        MSHookMessageEx(VisualCueClass, 
                        @selector(setAimAngle:), 
                        (IMP)hook_VisualCue_setAimAngle, 
                        (IMP*)&orig_VisualCue_setAimAngle);
    }

    // BallManager Hook
    Class BallManagerClass = objc_getClass("BallManager");
    if (BallManagerClass) {
        MSHookMessageEx(BallManagerClass, 
                        @selector(getBallPositionForNumber:), 
                        (IMP)hook_BallManager_getBallPositionForNumber, 
                        (IMP*)&orig_BallManager_getBallPositionForNumber);
    }

    // Table Hook
    Class TableClass = objc_getClass("Table");
    if (TableClass) {
        MSHookMessageEx(TableClass, 
                        @selector(tableBounds), 
                        (IMP)hook_Table_tableBounds, 
                        (IMP*)&orig_Table_tableBounds);
    }
}