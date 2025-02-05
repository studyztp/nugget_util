#include "common.h"

uint64_t IR_inst_counter = 0;

// Initialize arrays for basic block analysis
__attribute__((no_profile_instrument_function))
void init_array(uint64_t num_bbs) {
    total_num_bbs = num_bbs;
    bbv_array = (uint64_t**)malloc(current_array_size * sizeof(uint64_t*));
    count_stamp_array = (uint64_t**)malloc(current_array_size * sizeof(uint64_t*));
    counter_array = (uint64_t*)malloc(current_array_size * sizeof(uint64_t));
    if (bbv_array == NULL || count_stamp_array == NULL || counter_array == NULL) {
            printf("Failed to allocate memory for bbv_array and count_stamp_array arrays\n");
            exit(1);
    }
    for (uint64_t i = 0; i < current_array_size; i++) {
        bbv_array[i] = (uint64_t*)malloc((total_num_bbs) * sizeof(uint64_t));
        count_stamp_array[i] = (uint64_t*)malloc((total_num_bbs) * sizeof(uint64_t));
        if (bbv_array[i] == NULL || count_stamp_array[i] == NULL) {
            printf("Failed to allocate memory for bbv_array and count_stamp_array arrays\n");
            exit(1);
        }
        memset(bbv_array[i], 0, total_num_bbs * sizeof(uint64_t));
        memset(count_stamp_array[i], 0, total_num_bbs * sizeof(uint64_t));
    }
    bbv = bbv_array[region];
    count_stamp = count_stamp_array[region];
}

// Process collected data and prepare for the next region
void process_data() {
    counter_array[region] = IR_inst_counter;
    region ++;
    bbv = bbv_array[region];
    count_stamp = count_stamp_array[region];
    if (region + 100 >= current_array_size) {
        increase_array();
    }
    IR_inst_counter = 0;
}

// Hook function to analyze basic blocks
void bb_hook(uint64_t bb_inst, uint64_t bb_id, uint64_t threshold) {
    if (if_start) {
        IR_inst_counter += bb_inst;
        bbv[bb_id] += 1;
        count_stamp[bb_id] = IR_inst_counter;
        if (IR_inst_counter > threshold) {
            process_data();
        }
    }
}

// Mark the beginning of the region of interest (ROI)
void roi_begin_() {
    if_start = TRUE;
    printf("ROI begin\n");
}

// Mark the end of the region of interest (ROI) and output results
void roi_end_() {
    if_start = FALSE;
    process_data();
    char outputfile[] = "analysis-output.csv";
    FILE* fptr = fopen(outputfile, "w");
    if (fptr == NULL) {
        printf("Error: cannot open file\n");
        exit(1);
    }
    fprintf(fptr, "type,region,thread,data\n");
    for (uint64_t i = 0; i < region; i ++) {
        fprintf(fptr, "bbv,%llu,0", i);
        for (uint64_t k = 0; k < total_num_bbs; k ++) {
            if (bbv_array[i][k] != 0) {
                fprintf(fptr, ",%llu", bbv_array[i][k]);
            }
        }
        fprintf(fptr, "\n");
        fprintf(fptr, "csv,%llu,0", i);
        for (uint64_t k = 0; k < total_num_bbs; k ++) {
            if (count_stamp_array[i][k] != 0) {
                fprintf(fptr, ",%llu", count_stamp_array[i][k]);
            }
        }
        fprintf(fptr, "\n");
        fprintf(fptr, "bb_id,%llu,0", i);
        for (uint64_t k = 0; k < total_num_bbs; k ++) {
            if (bbv_array[i][k] != 0) {
                fprintf(fptr, ",%llu", k);
            }
        }
        fprintf(fptr, "\n");
    }
    fprintf(fptr, "region_inst,N/A,N/A");
    for (uint64_t i = 0; i < region; i++) {
        fprintf(fptr, ",%llu", counter_array[i]);
    }
    fprintf(fptr, "\n");
    fclose(fptr);
    delete_array();
    printf("ROI end\n");
    printf("Region: %llu\n", region);
    printf("Total IR instructions: %llu\n", total_IR_inst);
}

// Free allocated memory for arrays
void delete_array() {
    for (uint64_t i = 0; i < current_array_size; i++) {
        free(bbv_array[i]);
        free(count_stamp_array[i]);
    }
    free(bbv_array);
    free(count_stamp_array);
    free(counter_array);
}
