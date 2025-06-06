#include "common.h"
#include <omp.h>
#include <stdatomic.h>

#include "gem5/m5ops.h"
#include "gem5/m5_mmap.h"

uint64_t warmup_threshold;

atomic_ullong warmup_counter;

uint64_t num_threads = 0;

BOOL if_warmup_not_met = FALSE;

void warmup_event() {
    m5_work_begin_addr(0,0);
}

void start_event() {
}

void end_event() {
}

void roi_begin_() {
    num_threads = omp_get_max_threads();
    if_warmup_not_met = TRUE;
    map_m5_mem();
    m5_work_begin_addr(0,0);
    printf("ROI begin\n");
}

void roi_end_() {
    m5_work_end(0,0);
    unmap_m5_mem();
    printf("ROI end\n");
}

void warmup_hook() {
    if (if_warmup_not_met) {
        uint64_t curr_count = atomic_fetch_add(&warmup_counter, 1) + 1;
        if (curr_count == warmup_threshold) {
            warmup_event();
            if_warmup_not_met = FALSE;
        }
    }
}

void start_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization

}

void end_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization
}

void setup_threshold(uint64_t warm_up, uint64_t start, uint64_t end) {
/*
 * :param: warm_up: the threshold for the warm up marker
 * :param: start: the threshold for the start marker
 * :param: end: the threshold for the end marker
 * 
 * this function is used to set the thresholds for the warm up, start and end
 * markers
*/
    warmup_threshold = warm_up;
    if (warmup_threshold == 0) {
        warmup_threshold = 1;
    }

    printf("Warmup threshold: %llu\n", warmup_threshold);

    atomic_init(&warmup_counter, 0);
}

