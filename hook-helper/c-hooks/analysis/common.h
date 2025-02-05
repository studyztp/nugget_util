#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#ifndef BOOL
typedef enum { FALSE = 0, TRUE = 1 } BOOL;
#endif

#ifndef uint64_t
#define uint64_t unsigned long long
#endif

#define ARRAY_SIZE 1000

BOOL if_start = FALSE;

uint64_t region = 0;
uint64_t total_num_bbs = 0;
uint64_t current_array_size = ARRAY_SIZE;
uint64_t total_IR_inst = 0;
uint64_t IR_inst_counter = 0;

uint64_t** bbv_array;
uint64_t** count_stamp_array;

uint64_t* bbv;
uint64_t* count_stamp;
uint64_t* counter_array;

__attribute__((no_profile_instrument_function))
void roi_begin_();

__attribute__((no_profile_instrument_function))
void roi_end_();

__attribute__((no_profile_instrument_function))
void delete_array();

__attribute__((no_profile_instrument_function))
void increase_array();

__attribute__((no_profile_instrument_function))
void process_data();

__attribute__((no_profile_instrument_function))
void bb_hook(
    unsigned long long bb_inst, 
    unsigned long long bb_id, 
    unsigned long long threshold
);

