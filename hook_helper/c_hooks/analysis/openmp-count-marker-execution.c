#include "common.h"
#include <omp.h>
#include <time.h> 
#include <stdatomic.h>

atomic_ullong marker_counter;
BOOL if_start = FALSE;

void warmup_event() {
}

void start_event() {
}

void end_event() {
}

void roi_begin_() {
    if_start = TRUE;
    printf("ROI begin\n");
}

void roi_end_() {
    FILE *fptr = fopen("counts.txt", "a");
    if (fptr == NULL) {
        perror("Error opening counts.txt");
        exit(EXIT_FAILURE);
    }
    // grab the counter once so we don’t race between loads
    uint64_t count = atomic_load(&marker_counter);

    fprintf(fptr, "Count: %llu\n", (unsigned long long)count);
    fclose(fptr);

    printf("count: %llu\n", (unsigned long long)count);
    printf("ROI end\n");
}

void warmup_hook() {
}

void start_hook() {
}

void end_hook() {
    if (if_start) {
        atomic_fetch_add(&marker_counter, 1);
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
}

