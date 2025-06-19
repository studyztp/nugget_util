#include "common.h"
#include "gem5/m5ops.h"
#include "gem5/m5_mmap.h"

uint64_t counter = 0;

uint64_t warmup_threshold;

BOOL if_warmup_not_met = FALSE;

void warmup_event() {
}

void start_event() {
}

void end_event() {
}

void roi_begin_() {
    if_warmup_not_met = TRUE;
    m5_work_begin(0,0);
    printf("ROI begin\n");
}

void roi_end_() {
    m5_work_end(0,0);
    printf("ROI end\n");
}

void setup_threshold(uint64_t warmup, uint64_t start, uint64_t end) {
    printf("Warmup threshold: %llu\n", warmup_threshold);
    printf("Start threshold: %llu\n", start);
    printf("End threshold: %llu\n", end);
}

void warmup_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization
}

void start_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization
}

void end_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization
}
