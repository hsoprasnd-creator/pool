#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Global hooks references
double g_liveAimAngle = 0.0;
id __weak g_tableInstance = nil;
id __weak g_ballManagerInstance = nil;

typedef struct { float x; float y; float width; float height; } MCRect;
MCRect g_tableBounds = {100.0f, 100.0f, 700.0f, 400.0f};

// Method Swizzling Helper (Substrate-Free Bypass)
static void SafeSwizzle(Class cls, SEL origSel, SEL newSel, IMP newImp, const char *types) {
    if (!cls) return;
    class_addMethod(cls, newSel, newImp, types);
    Method origMethod = class_getInstanceMethod(cls, origSel);
    Method newMethod = class_getInstanceMethod(cls, newSel);
    if (origMethod && newMethod) {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

// 1. Hook VisualCue
static void swizzled_VisualCue_setAimAngle(id self, SEL _cmd, void *mcNumberPtr) {
    if (mcNumberPtr != NULL) {
        g_liveAimAngle = *(double *)mcNumberPtr;
    }
    // Call original implementation via renamed selector
    SEL origSel = @selector(swizzled_VisualCue_setAimAngle:);
    if ([self respondsToSelector:origSel]) {
        ((void(*)(id, SEL, void*))objc_msgSend)(self, origSel, mcNumberPtr);
    }
}

// 2. Hook BallManager
static CGPoint swizzled_BallManager_getBallPositionForNumber(id self, SEL _cmd, unsigned int num) {
    if (self) {
        g_ballManagerInstance = self;
    }
    SEL origSel = @selector(swizzled_BallManager_getBallPositionForNumber:);
    if ([self respondsToSelector:origSel]) {
        return ((CGPoint(*)(id, SEL, unsigned int))objc_msgSend)(self, origSel, num);
    }
    return CGPointZero;
}

// 3. Hook Table Bounds
static MCRect swizzled_Table_tableBounds(id self, SEL _cmd) {
    if (self) {
        g_tableInstance = self;
        SEL origSel = @selector(swizzled_Table_tableBounds);
        if ([self respondsToSelector:origSel]) {
            g_tableBounds = ((MCRect(*)(id, SEL))objc_msgSend)(self, origSel);
        }
    }
    return g_tableBounds;
}

extern void InitImGuiHook();

// Delayed initialization to let game load security checks first
__attribute__((constructor))
static void InitPoolDylib() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class VisualCueClass = objc_getClass("VisualCue");
        if (VisualCueClass) {
            SafeSwizzle(VisualCueClass, 
                        @selector(setAimAngle:), 
                        @selector(swizzled_VisualCue_setAimAngle:), 
                        (IMP)swizzled_VisualCue_setAimAngle, 
                        "v@:^v");
        }

        Class BallManagerClass = objc_getClass("BallManager");
        if (BallManagerClass) {
            SafeSwizzle(BallManagerClass, 
                        @selector(getBallPositionForNumber:), 
                        @selector(swizzled_BallManager_getBallPositionForNumber:), 
                        (IMP)swizzled_BallManager_getBallPositionForNumber, 
                        "{CGPoint=dd}@:I");
        }

        Class TableClass = objc_getClass("Table");
        if (TableClass) {
            SafeSwizzle(TableClass, 
                        @selector(tableBounds), 
                        @selector(swizzled_Table_tableBounds), 
                        (IMP)swizzled_Table_tableBounds, 
                        "{MCRect=ffff}@:");
        }

        InitImGuiHook();
    });
}
