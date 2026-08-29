TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PoolPrediction

PoolPrediction_FILES = main.mm \
                       ImGuiHook.mm \
                       imgui/imgui.cpp \
                       imgui/imgui_draw.cpp \
                       imgui/imgui_widgets.cpp \
                       imgui/imgui_tables.cpp \
                       imgui/imgui_impl_metal.mm

PoolPrediction_FRAMEWORKS = UIKit Foundation CoreGraphics Metal MetalKit QuartzCore
PoolPrediction_CFLAGS = -fobjc-arc -Iimgui -I. -Wno-error
PoolPrediction_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk