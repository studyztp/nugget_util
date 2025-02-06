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

uint64_t warmup_threshold;
uint64_t start_threshold;
uint64_t end_threshold;

BOOL if_warmup_not_met = FALSE;
BOOL if_start_not_met = FALSE;
BOOL if_end_not_met = FALSE;

__attribute__((no_profile_instrument_function))
void warmup_event();

__attribute__((no_profile_instrument_function))
void start_event();

__attribute__((no_profile_instrument_function))
void end_event();

__attribute__((no_profile_instrument_function))
void roi_begin_();

__attribute__((no_profile_instrument_function))
void roi_end_();

__attribute__((no_profile_instrument_function))
void setup_threshold(uint64_t warm_up, uint64_t start, uint64_t end);

__attribute__((no_profile_instrument_function))
void warmup_hook();

__attribute__((no_profile_instrument_function))
void start_hook();

__attribute__((no_profile_instrument_function))
void end_hook();
