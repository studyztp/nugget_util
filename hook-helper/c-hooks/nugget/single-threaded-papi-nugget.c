#include "common.h"
#include <papi.h>

uint64_t counter = 0;

uint64_t warmup_threshold;
uint64_t start_threshold;
uint64_t end_threshold;

void warmup_event() {
    printf("Warmup event\n");
}

void start_event() {
    printf("Start event\n");
    int retval = PAPI_hl_region_begin("0");
    if (retval != PAPI_OK) {
        printf("PAPI_hl_region_begin failed due to %d.\n", retval);
    }
}

void end_event() {
    int retval = PAPI_hl_region_end("0");
    if (retval != PAPI_OK) {
        printf("PAPI_hl_region_end failed due to %d.\n", retval);
    }
    printf("End event\n");
}

void roi_begin_() {
    if_warmup_not_met = TRUE;

    int retval = PAPI_library_init(PAPI_VER_CURRENT);
    if (retval != PAPI_VER_CURRENT) {
        printf("PAPI_library_init failed due to %d.\n", retval);
    }
    retval = PAPI_set_domain(PAPI_DOM_ALL);
    if (retval != PAPI_OK) {
        printf("PAPI_set_domain failed due to %d.\n", retval);
    }

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
