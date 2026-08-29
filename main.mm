#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

// KittyMemory header
#include "src/KittyMemory/KittyMemory.hpp"

// ============================================================
//  TYPE DEFINITIONS
// ============================================================
typedef struct { float x; float y; float width; float height; } MCRect;

// ============================================================
//  OFFSETS (EXACT VALUES FROM GAME BINARY)
// ============================================================
#define OFFSET_VISUALCUE_SET_AIMANGLE               0x1D1DA0
#define OFFSET_BALLMANAGER_GETBALLPOSITIONFORNUMBER 0x9FDA4
#define OFFSET_TABLE_TABLEBOUNDS                    0xA4024

// ============================================================
//  GLOBAL VARIABLES (Prediction Engine ke liye)
// ============================================================
double g_liveAimAngle = 0.0;
id g_tableInstance = nil;
id g_ballManagerInstance = nil;

// ============================================================
//  ORIGINAL FUNCTION POINTERS
// ============================================================
void (*orig_VisualCue_setAimAngle)(id self, SEL _cmd, void *mcNumberPtr);
CGPoint (*orig_BallManager_getBallPositionForNumber)(id self, SEL _cmd, unsigned int num) = NULL;
MCRect (*orig_Table_tableBounds)(id self, SEL _cmd);

// ============================================================
//  HOOK FUNCTIONS (Replacement IMPs)
// ============================================================
static void hook_VisualCue_setAimAngle(id self, SEL _cmd, void *mcNumberPtr) {
    if (mcNumberPtr) {
        g_liveAimAngle = *(double *)mcNumberPtr;
    }
    orig_VisualCue_setAimAngle(self, _cmd, mcNumberPtr);
}

static CGPoint hook_BallManager_getBallPositionForNumber(id self, SEL _cmd, unsigned int num) {
    g_ballManagerInstance = self;
    return orig_BallManager_getBallPositionForNumber(self, _cmd, num);
}

static MCRect hook_Table_tableBounds(id self, SEL _cmd) {
    g_tableInstance = self;
    return orig_Table_tableBounds(self, _cmd);
}

// ============================================================
//  HOOK INJECTION (Using KittyMemory)
// ============================================================
void InjectPoolHooksSafely() {
    NSLog(@"[PoolPrediction] Starting delayed hook injection with KittyMemory...");

    uintptr_t slide = KittyMemory::getSlide();
    if (slide == 0) {
        NSLog(@"[PoolPrediction] Warning: getSlide returned 0, ASLR slide not available?");
    }

    // 1. VisualCue::setAimAngle: (Offset: 0x1D1DA0)
    uintptr_t addrVisualCue = slide + OFFSET_VISUALCUE_SET_AIMANGLE;
    if (addrVisualCue) {
        if (KittyMemory::hookFunction((void*)addrVisualCue,
                                      (void*)&hook_VisualCue_setAimAngle,
                                      (void**)&orig_VisualCue_setAimAngle)) {
            NSLog(@"[PoolPrediction] VisualCue Hook Applied via KittyMemory.");
        } else {
            NSLog(@"[PoolPrediction] Failed to hook VisualCue.");
        }
    }

    // 2. BallManager::getBallPositionForNumber: (Offset: 0x9FDA4)
    uintptr_t addrBallManager = slide + OFFSET_BALLMANAGER_GETBALLPOSITIONFORNUMBER;
    if (addrBallManager) {
        if (KittyMemory::hookFunction((void*)addrBallManager,
                                      (void*)&hook_BallManager_getBallPositionForNumber,
                                      (void**)&orig_BallManager_getBallPositionForNumber)) {
            NSLog(@"[PoolPrediction] BallManager Hook Applied via KittyMemory.");
        } else {
            NSLog(@"[PoolPrediction] Failed to hook BallManager.");
        }
    }

    // 3. Table::tableBounds (Offset: 0xA4024)
    uintptr_t addrTable = slide + OFFSET_TABLE_TABLEBOUNDS;
    if (addrTable) {
        if (KittyMemory::hookFunction((void*)addrTable,
                                      (void*)&hook_Table_tableBounds,
                                      (void**)&orig_Table_tableBounds)) {
            NSLog(@"[PoolPrediction] Table Hook Applied via KittyMemory.");
        } else {
            NSLog(@"[PoolPrediction] Failed to hook Table.");
        }
    }
}

// ============================================================
//  DYLIB INITIALIZATION
// ============================================================
__attribute__((constructor))
static void InitPoolDylib() {
    NSLog(@"[PoolPrediction] Dylib Injected. Waiting for initialization...");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:12.0];

        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                InjectPoolHooksSafely();
            } @catch (NSException *exception) {
                NSLog(@"[PoolPrediction] Error during injection: %@", exception.reason);
            }
        });
    });
}
