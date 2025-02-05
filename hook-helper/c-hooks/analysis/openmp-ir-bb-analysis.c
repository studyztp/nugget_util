#include <stdatomic.h>
#include <omp.h>

#include "common.h"

atomic_ullong counter;

omp_lock_t lock;
BOOL wait = FALSE;

uint64_t num_threads = 0;

__attribute__((no_profile_instrument_function))
void init_array(uint64_t num_bbs) {
/*
 * :param: num_bbs: the total number of basic blocks in the program
 * this function is used to initialize the arrays for storing the data
*/
    total_num_bbs = num_bbs;
    // store the total number of basic blocks
    num_threads = omp_get_max_threads();
    bbv_array = (uint64_t**)malloc(current_array_size * sizeof(uint64_t*));
    count_stamp_array = (uint64_t**)malloc(current_array_size * sizeof(uint64_t*));
    counter_array = (uint64_t*)malloc(current_array_size * sizeof(uint64_t));
    if (bbv_array == NULL || count_stamp_array == NULL || counter_array == NULL) {
        printf("Failed to allocate memory for bbv_array and count_stamp_array arrays\n");
        exit(1);
    }

    for (uint64_t i = 0; i < current_array_size; i++) {
        bbv_array[i] = (uint64_t*)malloc(((total_num_bbs + 64) * num_threads) * sizeof(uint64_t));
        count_stamp_array[i] = (uint64_t*)malloc(((total_num_bbs + 64) * num_threads) * sizeof(uint64_t));
        if (bbv_array[i] == NULL || count_stamp_array[i] == NULL) {
            printf("Failed to allocate memory for bbv_array and count_stamp_array arrays\n");
            exit(1);
        }
        memset(bbv_array[i], 0, ((total_num_bbs + 64) * num_threads) * sizeof(uint64_t));
        memset(count_stamp_array[i], 0, ((total_num_bbs + 64) * num_threads) * sizeof(uint64_t));
    }
    bbv = bbv_array[0];
    count_stamp = count_stamp_array[0];
}

void process_data() {
/*
 * this function is used to store the data for the current region and reset
 * the counter for the next region.
 * only one thread will execute this function at each end of the region.
 */
    counter_array[region] = atomic_load(&counter);
    region ++;
    bbv = bbv_array[region];
    count_stamp = count_stamp_array[region];
    if (region + 100 >= current_array_size) {
    // increase the size of the arrays when the current size is not enough
        increase_array();
    }
    atomic_store(&counter, 0);
}

void bb_hook(uint64_t bb_inst, uint64_t bb_id, uint64_t threshold) {
/*
 * :param: bb_inst: the number of IR instructions in the basic block
 * :param: bb_id: the id of the basic block
 * :param: threshold: the threshold for the number of IR instructions in the 
 *  region
 * this function is designed to be called at the end of each IR basic block.
*/
    if(if_start) {
    // only start to count the IR instructions when the if_start is TRUE
        if (wait) {
        // if there is a thread reached the threshold, then wait for all the
        // threads to reach the threshold
            omp_set_lock(&lock);
            omp_unset_lock(&lock);
        }
        uint64_t thread_id = omp_get_thread_num();
        uint64_t index = thread_id * (total_num_bbs + 64) + bb_id;

        uint64_t cur_counter = atomic_fetch_add(&counter, bb_inst) + bb_inst;

        bbv[index] ++;
        count_stamp[index] = cur_counter;

        if (cur_counter >= threshold) {
            omp_set_lock(&lock);
            if (atomic_load(&counter) >= threshold) {
            // this ensures that only one thread will execute the process_data
            // function at each end of the region
                wait = TRUE;
                process_data();
                wait = FALSE;
            }
            omp_unset_lock(&lock);
        }
    }
}

void roi_begin_() {
/*
* this function is used to initialize the variables and arrays for the
* profiling.
* this is meant to be called at the beginning of the region of interest.
*/

    atomic_init(&counter, 0);
    omp_init_lock(&lock);
    if_start = TRUE;

    printf("ROI begin\n");
}

void roi_end_() {
/*
* this function is used to store the data for the last region and print the
* data to the output file.
* this is meant to be called at the end of the region of interest.
*/

    if_start = FALSE;
    omp_destroy_lock(&lock);

    process_data();
    // store the data for the last region

    char outputfile[] = "analysis-output.csv";

    FILE *fptr;
    fptr = fopen(outputfile, "w");
    if (fptr == NULL) {
        printf("Faile to open outputfile\n");
        exit(1);
    }

    unsigned long long total_IR_inst = 0;
    unsigned long long index = 0;

    fprintf(fptr, "type,region,thread,data\n");

    for (unsigned long long i = 0; i < region; i++) {
        // the format of each line in the output file is:
        // type, region, thread, data

        for (unsigned long long j = 0; j < num_threads; j++) {
            fprintf(fptr, "bbv,%llu,%llu", i, j);
            index = j * (total_num_bbs + 64);
            for (unsigned long long k = 0; k < total_num_bbs; k++) {
                if (bbv_array[i][index] != 0) {
                    fprintf(fptr, ",%llu", bbv_array[i][index]);
                }
                index ++;
            }
            fprintf(fptr, "\n");

            fprintf(fptr, "csv,%llu,%llu", i, j);
            index = j * (total_num_bbs + 64);
            for (unsigned long long k = 0; k < total_num_bbs; k++) {
                if (count_stamp_array[i][index] != 0) {
                    fprintf(fptr, ",%llu", count_stamp_array[i][index]);
                }
                index ++;
            }
            fprintf(fptr, "\n");

            fprintf(fptr, "bb_id,%llu,%llu", i, j);
            index = j * (total_num_bbs + 64);
            for (unsigned long long k = 0; k < total_num_bbs; k++) {
                if (bbv_array[i][index] != 0) {
                    fprintf(fptr, ",%llu", k);
                }
                index ++;
            }
            fprintf(fptr, "\n");
        }
    }

    fprintf(fptr, "region_inst,N/A,N/A");
    for (unsigned long long i = 0; i < region; i++) {
        fprintf(fptr, ",%llu", counter_array[i]);
    }
    fprintf(fptr, "\n");

    fclose(fptr);

    delete_arrays();

    printf("ROI end\n");
    printf("Region: %llu\n", region);
    printf("Total IR instructions: %llu\n", total_IR_inst);
}

void delete_arrays() {
/*
 * this function is used to free the memory allocated for the arrays
*/
    for (unsigned long long i = 0; i < current_array_size; i++) {
        free(bbv_array[i]);
        free(count_stamp_array[i]);
    }
    free(bbv_array);
    free(count_stamp_array);
    free(counter_array);
}
