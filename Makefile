TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PoolPrediction

# All Source files (including KittyMemory.cpp)
PoolPrediction_FILES = main.mm \
                       ImGuiHook.mm \
                       imgui/imgui.cpp \
                       imgui/imgui_draw.cpp \
                       imgui/imgui_tables.cpp \
                       imgui/imgui_widgets.cpp \
                       imgui/imgui_impl_metal.mm \
                       src/KittyMemory/KittyMemory.cpp   # <-- Added

# Include paths – ab src folder bhi add karo
PoolPrediction_CFLAGS = -fobjc-arc -Iimgui -I. -Isrc
PoolPrediction_CCFLAGS = -std=c++17 -stdlib=libc++ -Iimgui -I. -Isrc
PoolPrediction_CXXFLAGS = -std=c++17 -stdlib=libc++ -Iimgui -I. -Isrc
PoolPrediction_OBJCXXFLAGS = -std=c++17 -stdlib=libc++ -fobjc-arc -Iimgui -I. -Isrc

# Frameworks
PoolPrediction_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
