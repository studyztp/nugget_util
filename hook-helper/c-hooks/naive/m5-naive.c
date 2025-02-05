#include "common.h"
#include "gem5/m5ops.h"

#if defined(USE_ADDR_VERSION_M5OPS_BEGIN) || defined(USE_ADDR_VERSION_M5OPS_END)
#include "gem5/m5_mmap.h"
#endif

void roi_begin_() {
    printf("ROI begin\n");
#if defined(USE_ADDR_VERSION_M5OPS_BEGIN) || defined(USE_ADDR_VERSION_M5OPS_END)
    map_m5_mem();
#if defined(USE_ADDR_VERSION_M5OPS_BEGIN)
    m5_hypercall_addr(1);
#else
    m5_hypercall(1);
#endif
}

void roi_end_() {
    printf("ROI end\n");
#ifdef USE_ADDR_VERSION_M5OPS_END
    m5_hypercall_addr(2);
    unmap_m5_mem();
#else
    m5_hypercall(2);
#endif
}
