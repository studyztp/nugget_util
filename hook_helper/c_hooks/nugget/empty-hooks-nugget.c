#include "common.h"
#include <sys/syscall.h>
#include <unistd.h>
#define SYS_TRACKING_START 888
#define SYS_TRACKING_STOP  889

void warmup_event() {
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
