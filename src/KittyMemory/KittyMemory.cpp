#include "KittyMemory.hpp"
#include <mach/mach_vm.h>
#include <pthread.h>

namespace KittyMemory {

    // ---------- Global Mutex for thread safety ----------
    static std::mutex g_KittyMutex;

    // ---------- Get ASLR Slide ----------
    uintptr_t getSlide() {
        // _dyld_get_image_vmaddr_slide(0) main binary ka slide return karta hai
        return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
    }

    // ---------- Make memory writable ----------
    bool makeWritable(void *address, size_t len) {
        mach_port_t task = mach_task_self();
        kern_return_t kr;
        
        // Page alignment nikaalo
        vm_address_t page_start = (vm_address_t)address & ~(vm_page_size - 1);
        vm_size_t page_len = len + ((vm_address_t)address - page_start);
        page_len = (page_len + vm_page_size - 1) & ~(vm_page_size - 1);
        
        kr = mach_vm_protect(task, page_start, (mach_vm_size_t)page_len, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) {
            // Agar mach_vm_protect fail ho, toh mprotect try karo (iOS 15+ ke liye)
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
        
        // ARM64 cache flush (instruction cache clear)
        __builtin___clear_cache((char *)address, (char *)address + len);
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

        // Target ke first 16 bytes (ARM64 branch instruction) backup kar lo
        uint8_t original_bytes[16];
        memRead(target, original_bytes, 16);

        // ARM64 branch instruction banayein: "BLR X16" + "MOV X16, address" ke liye
        // Actually, standard KittyMemory uses absolute branch via ADRP + ADD + BLR X16.
        // Lekin simple aur reliable tareeqa: LDR X16, [PC] ; BLR X16 ; (address store)
        // Iske liye 16 bytes ka patch:
        // 0x50 0x00 0x00 0x58 (LDR X16, [PC, #0x0]) ; 0x00 0x02 0x1F 0xD6 (BLR X16) ; 0x00 0x00 0x00 0x00 (address low) ; 0x00 0x00 0x00 0x00 (address high)
        // But easier standard method: ADRP X17, page ; ADD X17, X17, offset ; BLR X17 - But computing page/offset is complex.
        
        // I'll implement the simplest ARM64 absolute jump: 
        // LDR X16, [PC, #0x8] ; BR X16 ; <Target address 8 bytes>
        // Opcode: LDR X16, [PC, #0x8] = 0x50 0x00 0x00 0x58
        // Opcode: BR X16 = 0x00 0x02 0x1F 0xD6
        uint8_t shellcode[] = {
            0x50, 0x00, 0x00, 0x58, // LDR X16, [PC, #8]
            0x00, 0x02, 0x1F, 0xD6, // BR X16
        };
        
        // Original function pointer store karo (pehle 16 bytes ya full function? 
        // Agar original function call chahiye toh hum detour banate hain.
        // Humein sirf original pointer chahiye tha function call karne ke liye.
        // Lekin original bytes hume wapas original implementation jump karne ke liye chahiye.
        // Isliye hum tumhe original bytes wapas nahi, balke ek "trampoline" banate hain.
        // Simple approach: original function ko call karne ke liye hum *original pointer ko
        // jump karne wali memory allocate karte hain. But yahan pe humne sirf original bytes
        // store karke, unhein execute karte hain. 
        
        // Overwrite target with branch to replacement
        uint8_t hook_code[16];
        memcpy(hook_code, shellcode, 8);
        uintptr_t target_addr = (uintptr_t)replacement;
        memcpy(hook_code + 8, &target_addr, 8);
        
        if (!memWrite(target, hook_code, 16)) {
            return false;
        }

        // Original bytes ko preserve karne ke liye, ek naya executable memory allocate karo
        // jisko call kiya ja sake. Lekin yahan pe hum original bytes hi store kar lete hain.
        // Aur agar original function call chahiye, toh hum original_bytes ko ek executable
        // page par copy karke usko call karte hain. 
        // Simplest: We just return the original bytes pointer, but calling it will crash.
        // Isliye hum ek "trampoline" allocate karte hain.
        
        // Let's implement properly: Allocate executable memory for trampoline
        mach_port_t task = mach_task_self();
        void *trampoline = NULL;
        vm_size_t size = 0x1000; // Page size
        
        kern_return_t kr = mach_vm_allocate(task, (vm_address_t *)&trampoline, size, VM_FLAGS_ANYWHERE);
        if (kr != KERN_SUCCESS) {
            // Fallback: mprotect on original space, but we cannot modify original bytes multiple times.
            // Better: use mmap
            trampoline = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0);
            if (trample == MAP_FAILED) {
                return false;
            }
        }
        
        // Original bytes ko trampoline par copy karo
        memcpy(trampoline, original_bytes, 16);
        
        // Original bytes ke aage ek branch instruction daal do jo target + 16 par jump kare (return to original code flow)
        // Original bytes + 16 par jaane ke liye: LDR X16, [PC, #8] ; BR X16 ; (target+16)
        uint8_t ret_code[16];
        memcpy(ret_code, shellcode, 8);
        uintptr_t ret_addr = (uintptr_t)target + 16;
        memcpy(ret_code + 8, &ret_addr, 8);
        
        // Is ret_code ko trampoline ke baad likho
        memcpy((char *)trampoline + 16, ret_code, 16);
        
        // __builtin___clear_cache for trampoline
        __builtin___clear_cache((char *)trampoline, (char *)trampoline + 0x1000);
        
        // Set original to trampoline
        *((void **)original) = trampoline;
        
        return true;
    }

} // namespace KittyMemory