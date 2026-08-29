TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PoolPrediction

# All Source files compilation tree map pointers mapping arrays
PoolPrediction_FILES = main.mm \
                       ImGuiHook.mm \
                       imgui/imgui.cpp \
                       imgui/imgui_draw.cpp \
                       imgui/imgui_tables.cpp \
                       imgui/imgui_widgets.cpp \
                       imgui/imgui_impl_metal.mm

# Core include folders alignment mapping syntax configs
PoolPrediction_CFLAGS = -fobjc-arc -Iimgui -I.
PoolPrediction_CCFLAGS = -std=c++17 -stdlib=libc++ -Iimgui -I.
PoolPrediction_CXXFLAGS = -std=c++17 -stdlib=libc++ -Iimgui -I.
PoolPrediction_OBJCXXFLAGS = -std=c++17 -stdlib=libc++ -fobjc-arc -Iimgui -I.

# Frameworks mapping modules references links parameters UI definitions
PoolPrediction_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
