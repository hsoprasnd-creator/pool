TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PoolPrediction

# Source files (all .c, .cpp, .m, .mm)
PoolPrediction_FILES = main.mm ImGuiHook.mm fishhook.c \
                       imgui/imgui.cpp imgui/imgui_draw.cpp \
                       imgui/imgui_tables.cpp imgui/imgui_widgets.cpp \
                       imgui/imgui_impl_metal.mm

# Include paths
PoolPrediction_INC = -I./imgui -I.

# Compiler Flags: Enable C++17 for Modern ImGui support
PoolPrediction_CFLAGS += -fobjc-arc $(PoolPrediction_INC)
PoolPrediction_CXXFLAGS += -std=c++17 -fno-rtti $(PoolPrediction_INC)
PoolPrediction_OBJCXXFLAGS += -std=c++17 -fobjc-arc $(PoolPrediction_INC)

# Required iOS Frameworks
PoolPrediction_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
