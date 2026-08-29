TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PoolPrediction

# All Source files
PoolPrediction_FILES = main.mm ImGuiHook.mm fishhook.c \
                       imgui/imgui.cpp imgui/imgui_draw.cpp \
                       imgui/imgui_tables.cpp imgui/imgui_widgets.cpp \
                       imgui/imgui_impl_metal.mm

# Explicit Compiler Flags for Objective-C++ (.mm) and C++ (.cpp)
PoolPrediction_CFLAGS += -fobjc-arc -I./imgui -I.
PoolPrediction_CCFLAGS += -std=c++17 -stdlib=libc++ -I./imgui -I.
PoolPrediction_CXXFLAGS += -std=c++17 -stdlib=libc++ -I./imgui -I.
PoolPrediction_OBJCXXFLAGS += -std=c++17 -stdlib=libc++ -fobjc-arc -I./imgui -I.

# Frameworks
PoolPrediction_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
