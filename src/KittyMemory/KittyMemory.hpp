#pragma once

#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <mutex>

namespace KittyMemory {

    // ASLR Slide nikaalne ke liye (main binary ka)
    uintptr_t getSlide();
    
    // Function Hook karne ke liye
    // Returns: true agar hook successful, false agar fail
    bool hookFunction(void *target, void *replacement, void **original);
    
    // Memory patch karne ke liye (extra utility)
    bool memWrite(void *address, const void *buffer, size_t len);
    bool memRead(void *address, void *buffer, size_t len);

    // Internal: Page protection change karne ke liye
    bool makeWritable(void *address, size_t len);
}