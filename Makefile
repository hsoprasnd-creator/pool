TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PoolPrediction

PoolPrediction_FILES = main.mm \
                       ImGuiHook.mm \
                       src/KittyMemory/KittyMemory.cpp \
                       imgui/imgui.cpp \
                       imgui/imgui_draw.cpp \
                       imgui/imgui_tables.cpp \
                       imgui/imgui_widgets.cpp \
                       imgui/imgui_impl_metal.mm

PoolPrediction_CFLAGS = -fobjc-arc -Iimgui -I. -Isrc
PoolPrediction_CCFLAGS = -std=c++17 -stdlib=libc++ -Iimgui -I. -Isrc
PoolPrediction_CXXFLAGS = -std=c++17 -stdlib=libc++ -Iimgui -I. -Isrc
PoolPrediction_OBJCXXFLAGS = -std=c++17 -stdlib=libc++ -fobjc-arc -Iimgui -I. -Isrc

PoolPrediction_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore CoreGraphics
PoolPrediction_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
