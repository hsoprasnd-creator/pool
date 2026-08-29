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

// Separate function to safely inject hooks after security check passes
void InjectPoolHooksSafely() {
    NSLog(@"[PoolPrediction] Starting delayed hook injection...");

    // VisualCue Hook
    Class VisualCueClass = objc_getClass("VisualCue");
    if (VisualCueClass) {
        MSHookMessageEx(VisualCueClass, 
                        @selector(setAimAngle:), 
                        (IMP)hook_VisualCue_setAimAngle, 
                        (IMP*)&orig_VisualCue_setAimAngle);
        NSLog(@"[PoolPrediction] VisualCue Hook Applied.");
    }

    // BallManager Hook
    Class BallManagerClass = objc_getClass("BallManager");
    if (BallManagerClass) {
        MSHookMessageEx(BallManagerClass, 
                        @selector(getBallPositionForNumber:), 
                        (IMP)hook_BallManager_getBallPositionForNumber, 
                        (IMP*)&orig_BallManager_getBallPositionForNumber);
        NSLog(@"[PoolPrediction] BallManager Hook Applied.");
    }

    // Table Hook
    Class TableClass = objc_getClass("Table");
    if (TableClass) {
        MSHookMessageEx(TableClass, 
                        @selector(tableBounds), 
                        (IMP)hook_Table_tableBounds, 
                        (IMP*)&orig_Table_tableBounds);
        NSLog(@"[PoolPrediction] Table Hook Applied.");
    }
}

// 4. Delayed Execution on Dylib Load (Anti-Cheat Bypass)
__attribute__((constructor))
static void InitPoolDylib() {
    NSLog(@"[PoolPrediction] Dylib Injected. Waiting for security checks to clear...");

    // Background thread use karenge taaki main UI thread freeze na ho aur app crash na kare
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 12-15 seconds ka delay, taaki game fully load ho jaye aur anti-cheat check khatam ho jaye
        [NSThread sleepForTimeInterval:12.0];
        
        // Hooks ko main thread par wapas execute karenge safety ke liye
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                InjectPoolHooksSafely();
            } @catch (NSException *exception) {
                NSLog(@"[PoolPrediction] Error occurred during injection: %@", exception.reason);
            }
        });
    });
}
