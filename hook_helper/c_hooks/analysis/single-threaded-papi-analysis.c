#include "common.h"
#include <papi.h>

uint64_t IR_inst_counter = 0;

BOOL if_start = FALSE;
uint64_t region = 0;
uint64_t total_IR_inst = 0;

void increase_array() {
}

// Initialize arrays for basic block analysis
__attribute__((no_profile_instrument_function))
void init_array(uint64_t num_bbs) {
}

// Process collected data and prepare for the next region
void process_data() {
    char region_str[32];  // Buffer large enough for uint64_t
    snprintf(region_str, sizeof(region_str), "Region_%llu", region);

    int retval = PAPI_hl_region_end(region_str);
    if (retval != PAPI_OK) {
        printf("PAPI_hl_region_end failed due to %d.\n", retval);
    }

    region ++;
    total_IR_inst += IR_inst_counter;
    IR_inst_counter = 0;

    snprintf(region_str, sizeof(region_str), "Region_%llu", region);

    retval = PAPI_hl_region_begin(region_str);
    if (retval != PAPI_OK) {
        printf("PAPI_hl_region_begin failed due to %d.\n", retval);
    }

}

// Hook function to analyze basic blocks
__attribute__((no_profile_instrument_function))
void bb_hook(uint64_t bb_inst, uint64_t threshold) {
    if (if_start) {
        IR_inst_counter += bb_inst;
        if (IR_inst_counter > threshold) {
            process_data();
        }
    }
}

// Mark the beginning of the region of interest (ROI)
void roi_begin_() {
    char region_str[32];  // Buffer large enough for uint64_t
    snprintf(region_str, sizeof(region_str), "Region_%llu", region);
    int retval = PAPI_library_init(PAPI_VER_CURRENT);
    if (retval != PAPI_VER_CURRENT) {
        printf("PAPI_library_init failed due to %d.\n", retval);
    }
    retval = PAPI_set_domain(PAPI_DOM_ALL);
    if (retval != PAPI_OK) {
        printf("PAPI_set_domain failed due to %d.\n", retval);
    }
    printf("Finished PAPI initialization\n");
    if_start = TRUE;
    printf("ROI begin\n");
    retval = PAPI_hl_region_begin(region_str);
    if (retval != PAPI_OK) {
        printf("PAPI_hl_region_begin failed due to %d.\n", retval);
    }
}

// Mark the end of the region of interest (ROI) and output results
void roi_end_() {
    char region_str[32];  // Buffer large enough for uint64_t
    snprintf(region_str, sizeof(region_str), "Region_%llu", region);
    int retval = PAPI_hl_region_end(region_str);
    if (retval != PAPI_OK) {
        printf("PAPI_hl_region_end failed due to %d.\n", retval);
    }
    region ++;
    total_IR_inst += IR_inst_counter;

    if_start = FALSE;
    
    printf("ROI end\n");
    printf("Region: %llu\n", region);
    printf("Total IR instructions: %llu\n", total_IR_inst);
}

// Free allocated memory for arrays
void delete_array() {
}
