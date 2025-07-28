#include "common.h"
#include <time.h> 

uint64_t counter = 0;

uint64_t warmup_threshold;
uint64_t start_threshold;
uint64_t end_threshold;

BOOL if_warmup_not_met = FALSE;
BOOL if_start_not_met = FALSE;
BOOL if_end_not_met = FALSE;

struct timespec start, end;

__attribute__((no_profile_instrument_function))
unsigned long long calculate_nsec_difference(struct timespec start, struct timespec end) {
/*
 * :param: start: the start time
 * :param: end: the end time
 * :return: the difference between the two times in nanoseconds
*/
    long long nsec_diff = end.tv_nsec - start.tv_nsec;
    long long sec_diff = end.tv_sec - start.tv_sec;
    return sec_diff * 1000000000LL + nsec_diff;
}

void warmup_event() {
    printf("Warmup event\n");
}

void start_event() {
    printf("Start event\n");
    clock_gettime(CLOCK_MONOTONIC, &start);
}

void end_event() {
    clock_gettime(CLOCK_MONOTONIC, &end);
    uint64_t time_diff = calculate_nsec_difference(start, end);
    printf("Time taken: %lld ns\n", time_diff);

    char outputfile[] = "result.txt";

    FILE *fptr;
    fptr = fopen(outputfile, "w");
    if (fptr == NULL) {
        printf("Faile to open outputfile\n");
        exit(1);
    }

    fprintf(fptr, "Time taken: %lld ns\n", time_diff);

    fclose(fptr);
    exit(0);
}

void roi_begin_() {
    if_warmup_not_met = TRUE;
    
    printf("ROI begin\n");
}

void roi_end_() {
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
