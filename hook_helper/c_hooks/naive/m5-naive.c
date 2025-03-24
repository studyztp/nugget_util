#include "common.h"
#include "gem5/m5ops.h"

#if defined(USE_ADDR_VERSION_M5OPS_BEGIN) || defined(USE_ADDR_VERSION_M5OPS_END)
#include "gem5/m5_mmap.h"
#endif

void roi_begin_() {
    printf("ROI begin\n");
#if defined(USE_ADDR_VERSION_M5OPS_BEGIN) || defined(USE_ADDR_VERSION_M5OPS_END)
    map_m5_mem();
#endif

#if defined(USE_ADDR_VERSION_M5OPS_BEGIN)
    m5_work_begin_addr(0,0);
#else
    m5_work_begin(0,0);
#endif
}

void roi_end_() {
    printf("ROI end\n");
#ifdef USE_ADDR_VERSION_M5OPS_END
    m5_work_end_addr(0,0);
    unmap_m5_mem();
#else
    m5_work_end(0,0);
#endif
}
