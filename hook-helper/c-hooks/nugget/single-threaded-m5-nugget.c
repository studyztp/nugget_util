#include "common.h"

uint64_t counter = 0;

uint64_t warmup_threshold;
uint64_t start_threshold;
uint64_t end_threshold;

BOOL if_warmup_not_met = FALSE;
BOOL if_start_not_met = FALSE;
BOOL if_end_not_met = FALSE;


