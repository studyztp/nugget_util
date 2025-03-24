#include "common.h"
#include "gem5/m5ops.h"
#include "gem5/m5_mmap.h"

uint64_t counter = 0;

uint64_t warmup_threshold;
uint64_t start_threshold;
uint64_t end_threshold;

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

void setup_threshold(uint64_t warmup, uint64_t start, uint64_t end) {
    
    warmup_threshold = warmup;
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
}

void warmup_hook() {
    if (if_warmup_not_met) {
        counter ++;
        if (counter == warmup_threshold) {
            if_warmup_not_met = FALSE;
            printf("Warm up marker met\n");
            warmup_event();
            counter = 0;
            if_start_not_met = TRUE;
        }
    }
}

void start_hook() {
    if (if_start_not_met) {
        counter ++;
        if (counter == start_threshold) {
            if_start_not_met = FALSE;
            printf("Start marker met\n");
            start_event();
            counter = 0;
            if_end_not_met = TRUE;
        }
    }
}

void end_hook() {
    if (if_end_not_met) {
        counter ++;
        if (counter == end_threshold) {
            if_end_not_met = FALSE;
            printf("End marker met\n");
            end_event();
        }
    }
}
