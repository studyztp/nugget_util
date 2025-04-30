#include "common.h"
#include <sim_api.h>

void roi_begin_() {
    printf("ROI begin\n");
    // Start detailed ROI
    SimMarker(1, 1);
}

void roi_end_() {
    // End detailed ROI
    SimMarker(2, 2);
    printf("ROI end\n");
}
