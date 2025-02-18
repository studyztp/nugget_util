#ifndef HOOK_HELPER_COMMON_H
#define HOOK_HELPER_COMMON_H

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

extern BOOL if_warmup_not_met;
extern BOOL if_start_not_met;
extern BOOL if_end_not_met;

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

#ifdef __cplusplus
}
#endif

#endif // HOOK_HELPER_COMMON_H
