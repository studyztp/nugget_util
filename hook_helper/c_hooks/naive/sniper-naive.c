#include "common.h"
// #include <sim_api.h>

// Forward declaration of SimMarker
extern void SimMarker(int a, int b);

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
