#include "common.h"
#include <omp.h>
#include <stdatomic.h>

#include "gem5/m5ops.h"
#include "gem5/m5_mmap.h"

uint64_t warmup_threshold;
uint64_t start_threshold;
uint64_t end_threshold;

atomic_ullong warmup_counter;
atomic_ullong start_counter;
atomic_ullong end_counter;

uint64_t num_threads = 0;

BOOL if_warmup_not_met = FALSE;
BOOL if_start_not_met = FALSE;
BOOL if_end_not_met = FALSE;

void warmup_event() {
    m5_work_begin_addr(0,0);
}

void start_event() {
    m5_work_begin(0,0);
}

void end_event() {
    m5_work_end(0,0);
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
            if_start_not_met = TRUE;
        }
    }
}

void start_hook() {
    if (if_start_not_met) {
        uint64_t curr_count = atomic_fetch_add(&start_counter, 1) + 1;
        if (curr_count == start_threshold) {
            start_event();
            if_start_not_met = FALSE;
            if_end_not_met = TRUE;
        }
    }
}

void end_hook() {
    if (if_end_not_met) {
        uint64_t curr_count = atomic_fetch_add(&end_counter, 1) + 1;
        if (curr_count == end_threshold) {
            end_event();
            if_end_not_met = FALSE;
            atomic_store(&end_counter, 0);
        }
    }
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
    start_threshold = start;
    end_threshold = end;
    if (warmup_threshold == 0) {
        warmup_threshold = 1;
    }
    if (start_threshold == 0) {
        start_threshold = 1;
    }
    if (end_threshold == 0) {
        end_threshold = 1;
    }
    printf("Warmup threshold: %llu\n", warmup_threshold);
    printf("Start threshold: %llu\n", start_threshold);
    printf("End threshold: %llu\n", end_threshold);

    atomic_init(&warmup_counter, 0);
    atomic_init(&start_counter, 0);
    atomic_init(&end_counter, 0);
}

