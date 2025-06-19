#include "common.h"
#include <sys/syscall.h>
#include <unistd.h>
#define SYS_TRACKING_START 888
#define SYS_TRACKING_STOP  889
#define SYS_TRACKING_WARMUP 890

uint64_t counter = 0;

uint64_t warmup_threshold;

BOOL if_warmup_not_met = FALSE;

void warmup_event() {
    syscall(SYS_TRACKING_WARMUP);
    printf("Warmup event\n");
}

void start_event() {
}

void end_event() {
}

void roi_begin_() {
    syscall(SYS_TRACKING_START);
    printf("ROI begin\n");
}

void roi_end_() {
    syscall(SYS_TRACKING_STOP);
    printf("ROI end\n");
}

void setup_threshold(uint64_t warmup, uint64_t start, uint64_t end) {
    warmup_threshold = warmup;
    if (warmup_threshold == 0) {
        warmup_threshold = 1;
    }
    printf("Warmup threshold: %llu\n", warmup_threshold);
}

void warmup_hook() {
    if (if_warmup_not_met) {
        counter ++;
        if (counter == warmup_threshold) {
            if_warmup_not_met = FALSE;
            printf("Warm up marker met\n");
            warmup_event();
            counter = 0;
        }
    }
}

void start_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization
}

void end_hook() {
    asm volatile("" ::: "memory"); // Prevent optimization
}
