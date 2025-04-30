#include <stddef.h>
#include <sim_api.h>

#if defined(__aarch64__)

unsigned long SimMagic0(unsigned long cmd) {
    unsigned long res;
    asm volatile (
        "mov x1, %[x]\n"
        "\tbfm x0, x0, 0, 0\n"
        : [ret]"=r"(res)
        : [x]"r"(cmd)
    );
    return res;
}

unsigned long SimMagic1(unsigned long cmd, unsigned long arg0) {
    unsigned long res;
    asm volatile (
        "mov x1, %[x]\n"
        "\tmov x2, %[y]\n"
        "\tbfm x0, x0, 0, 0\n"
        : [ret]"=r"(res)
        : [x]"r"(cmd),
          [y]"r"(arg0)
        : "x2", "x1"
    );
    return res;
}

unsigned long SimMagic2(unsigned long cmd, unsigned long arg0, unsigned long arg1) {
    unsigned long res;
    asm volatile (
        "mov x1, %[x]\n"
        "\tmov x2, %[y]\n"
        "\tmov x3, %[z]\n"
        "\tbfm x0, x0, 0, 0\n"
        : [ret]"=r"(res)
        : [x]"r"(cmd),
          [y]"r"(arg0),
          [z]"r"(arg1)
        : "x1", "x2", "x3"
    );
    return res;
}

#else

unsigned long SimMagic0(unsigned long cmd) {
    unsigned long res;
    #if defined(__i386)
        #define REG "eax"
    #else
        #define REG "rax"
    #endif
    asm volatile (
        "mov %1, %%" REG "\n"
        "\txchg %%bx, %%bx\n"
        : "=a"(res)
        : "g"(cmd)
    );
    #undef REG
    return res;
}

unsigned long SimMagic1(unsigned long cmd, unsigned long arg0) {
    unsigned long res;
    #if defined(__i386)
        #define REG_A "eax"
        #define REG_B "edx"
    #else
        #define REG_A "rax"
        #define REG_B "rbx"
    #endif
    asm volatile (
        "mov %1, %%" REG_A "\n"
        "\tmov %2, %%" REG_B "\n"
        "\txchg %%bx, %%bx\n"
        : "=a"(res)
        : "g"(cmd),
          "g"(arg0)
        : "%" REG_B
    );
    #undef REG_A
    #undef REG_B
    return res;
}

unsigned long SimMagic2(unsigned long cmd, unsigned long arg0, unsigned long arg1) {
    unsigned long res;
    #if defined(__i386)
        #define REG_A "eax"
        #define REG_B "edx"
        #define REG_C "ecx"
    #else
        #define REG_A "rax"
        #define REG_B "rbx"
        #define REG_C "rcx"
    #endif
    asm volatile (
        "mov %1, %%" REG_A "\n"
        "\tmov %2, %%" REG_B "\n"
        "\tmov %3, %%" REG_C "\n"
        "\txchg %%bx, %%bx\n"
        : "=a"(res)
        : "g"(cmd),
          "g"(arg0),
          "g"(arg1)
        : "%" REG_B, "%" REG_C
    );
    #undef REG_A
    #undef REG_B
    #undef REG_C
    return res;
}

#endif

// High-level functions
void SimRoiStart(void) { SimMagic0(SIM_CMD_ROI_START); }
void SimRoiEnd(void) { SimMagic0(SIM_CMD_ROI_END); }
unsigned long SimGetProcId(void) { return SimMagic0(SIM_CMD_PROC_ID); }
unsigned long SimGetThreadId(void) { return SimMagic0(SIM_CMD_THREAD_ID); }
void SimSetThreadName(const char* name) { SimMagic1(SIM_CMD_SET_THREAD_NAME, (unsigned long)name); }
unsigned long SimGetNumProcs(void) { return SimMagic0(SIM_CMD_NUM_PROCS); }
unsigned long SimGetNumThreads(void) { return SimMagic0(SIM_CMD_NUM_THREADS); }
void SimSetFreqMHz(unsigned long proc, unsigned long mhz) { SimMagic2(SIM_CMD_MHZ_SET, proc, mhz); }
void SimSetOwnFreqMHz(unsigned long mhz) { SimSetFreqMHz(SimGetProcId(), mhz); }
unsigned long SimGetFreqMHz(unsigned long proc) { return SimMagic1(SIM_CMD_MHZ_GET, proc); }
unsigned long SimGetOwnFreqMHz(void) { return SimGetFreqMHz(SimGetProcId()); }
void SimMarker(unsigned long arg0, unsigned long arg1) { SimMagic2(SIM_CMD_MARKER, arg0, arg1); }
void SimNamedMarker(unsigned long arg0, const char* str) { SimMagic2(SIM_CMD_NAMED_MARKER, arg0, (unsigned long)str); }
void SimUser(unsigned long cmd, unsigned long arg) { SimMagic2(SIM_CMD_USER, cmd, arg); }
void SimSetInstrumentMode(unsigned long opt) { SimMagic1(SIM_CMD_INSTRUMENT_MODE, opt); }
int SimInSimulator(void) { return (SimMagic0(SIM_CMD_IN_SIMULATOR) != SIM_CMD_IN_SIMULATOR); }
