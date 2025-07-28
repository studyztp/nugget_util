#include "common.h"
#include <time.h> 

struct timespec start, end;

__attribute__((no_profile_instrument_function))
unsigned long long calculate_nsec_difference(struct timespec start, struct timespec end) {
/*
 * :param: start: the start time
 * :param: end: the end time
 * :return: the difference between the two times in nanoseconds
*/
    long long nsec_diff = end.tv_nsec - start.tv_nsec;
    long long sec_diff = end.tv_sec - start.tv_sec;
    return sec_diff * 1000000000LL + nsec_diff;
}

void roi_begin_() {
    printf("ROI started\n");
    clock_gettime(CLOCK_MONOTONIC, &start);
}

void roi_end_() {
    clock_gettime(CLOCK_MONOTONIC, &end);
    printf("ROI ended\n");
    uint64_t time_diff = calculate_nsec_difference(start, end);
    printf("Time taken: %lld ns\n", time_diff);

    char outputfile[] = "result.txt";

    FILE *fptr;
    fptr = fopen(outputfile, "w");
    if (fptr == NULL) {
        printf("Faile to open outputfile\n");
        exit(1);
    }

    fprintf(fptr, "Time taken: %lld ns\n", time_diff);

    fclose(fptr);
    exit(0);

}
