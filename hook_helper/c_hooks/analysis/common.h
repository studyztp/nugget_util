#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef BOOL
typedef enum { FALSE = 0, TRUE = 1 } BOOL;
#endif

#ifndef uint64_t
#define uint64_t unsigned long long
#endif

#define ARRAY_SIZE 1000

extern BOOL if_start;
extern uint64_t region;
extern uint64_t total_num_bbs;
extern uint64_t current_array_size;
extern uint64_t total_IR_inst;

extern uint64_t** bbv_array;
extern uint64_t** count_stamp_array;

extern uint64_t* bbv;
extern uint64_t* count_stamp;
extern uint64_t* counter_array;

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
    uint64_t bb_inst, 
    uint64_t bb_id, 
    uint64_t threshold
);

#ifdef __cplusplus
}
#endif

