#include "KittyMemory.hpp"
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/dyld.h>
#include <sys/mman.h>
#include <libkern/OSCacheControl.h>
#include <pthread.h>
#include <mutex>
#include <cstring>

namespace KittyMemory {

    // ---------- Global Mutex for thread safety ----------
    static std::mutex g_KittyMutex;

    // ---------- Get ASLR Slide ----------
    uintptr_t getSlide() {
        return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    }

    // ---------- Make memory writable ----------
    bool makeWritable(void *address, size_t len) {
        mach_port_t task = mach_task_self();
        
        vm_address_t page_start = (vm_address_t)address & ~(vm_page_size - 1);
        vm_size_t page_len = len + ((vm_address_t)address - page_start);
        page_len = (page_len + vm_page_size - 1) & ~(vm_page_size - 1);
        
        kern_return_t kr = vm_protect(task, page_start, page_len, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) {
            return mprotect((void *)page_start, page_len, PROT_READ | PROT_WRITE | PROT_EXEC) == 0;
        }
        return true;
    }

    // ---------- Memory Read/Write ----------
    bool memWrite(void *address, const void *buffer, size_t len) {
        std::lock_guard<std::mutex> lock(g_KittyMutex);
        if (!address || !buffer || len == 0) return false;
        
        if (!makeWritable(address, len)) {
            return false;
        }
        
        memcpy(address, buffer, len);
        
        // Native iOS instruction cache invalidation
        sys_icache_invalidate(address, len);
        return true;
    }

    bool memRead(void *address, void *buffer, size_t len) {
        std::lock_guard<std::mutex> lock(g_KittyMutex);
        if (!address || !buffer || len == 0) return false;
        memcpy(buffer, address, len);
        return true;
    }

    // ---------- Main Hook Function ----------
    bool hookFunction(void *target, void *replacement, void **original) {
        std::lock_guard<std::mutex> lock(g_KittyMutex);
        
        if (!target || !replacement) {
            return false;
        }

        uint8_t original_bytes[16];
        memRead(target, original_bytes, 16);

        // ARM64 absolute jump sequence: LDR X16, [PC, #8] ; BR X16
        uint8_t shellcode[] = {
            0x50, 0x00, 0x00, 0x58, // LDR X16, [PC, #8]
            0x00, 0x02, 0x1F, 0xD6  // BR X16
        };
        
        // Allocate executable memory for trampoline
        mach_port_t task = mach_task_self();
        void *trampoline = NULL;
        vm_size_t size = 0x1000;
        
        kern_return_t kr = vm_allocate(task, (vm_address_t *)&trampoline, size, VM_FLAGS_ANYWHERE);
        if (kr != KERN_SUCCESS) {
            trampoline = mmap(NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0);
            if (trampoline == MAP_FAILED) {
                return false;
            }
        } else {
            vm_protect(task, (vm_address_t)trampoline, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
        }
        
        // Copy original bytes to trampoline
        memcpy(trampoline, original_bytes, 16);
        
        // Return branch to target + 16
        uint8_t ret_code[16];
        memcpy(ret_code, shellcode, 8);
        uintptr_t ret_addr = (uintptr_t)target + 16;
        memcpy(ret_code + 8, &ret_addr, 8);
        
        memcpy((char *)trampoline + 16, ret_code, 16);
        
        // Invalidate cache for allocated trampoline
        sys_icache_invalidate(trampoline, size);
        
        // Write hook jump into target address
        uint8_t hook_code[16];
        memcpy(hook_code, shellcode, 8);
        uintptr_t target_addr = (uintptr_t)replacement;
        memcpy(hook_code + 8, &target_addr, 8);
        
        if (!memWrite(target, hook_code, 16)) {
            return false;
        }

        if (original) {
            *original = trampoline;
        }
        
        return true;
    }

} // namespace KittyMemory
