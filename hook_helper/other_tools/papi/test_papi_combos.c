// test_papi_combos.c
#include <stdio.h>
#include <stdlib.h>
#include <papi.h>

#define COMBO_SIZE 5
#define MAX_SUPPORTED_COMBOS 6188  // C(17,5)

static const char *event_names[] = {
    "PAPI_L1_ICM","PAPI_L2_DCM","PAPI_L2_ICM",
    "PAPI_TLB_DM","PAPI_TLB_IM","PAPI_BR_TKN",
    "PAPI_BR_MSP","PAPI_TOT_INS","PAPI_FP_INS",
    "PAPI_BR_INS","PAPI_TOT_CYC","PAPI_L2_DCH",
    "PAPI_L1_DCA","PAPI_L2_DCR","PAPI_L2_ICH",
    "PAPI_L2_ICR","PAPI_FP_OPS"
};

enum { NEVENTS = sizeof(event_names)/sizeof(event_names[0]) };

int event_codes[NEVENTS];

int  supported_idxs[MAX_SUPPORTED_COMBOS][COMBO_SIZE];
unsigned int supported_masks[MAX_SUPPORTED_COMBOS];
int nsupported = 0;

long long values[COMBO_SIZE];
long long total_tested = 0, total_supported = 0;

static void print_combo(const int idx[COMBO_SIZE]) {
	printf("[");
    for (int i = 0; i < COMBO_SIZE; i++) {
        printf("'%s%s", event_names[idx[i]], (i+1<COMBO_SIZE? "', " : "],\n"));
    }
}

static void test_one(int idx[COMBO_SIZE]) {
    int EventSet = PAPI_NULL;
    total_tested++;

    if (PAPI_create_eventset(&EventSet) != PAPI_OK)
        return;
    for (int i = 0; i < COMBO_SIZE; i++) {
        if (PAPI_add_event(EventSet, event_codes[idx[i]]) != PAPI_OK)
            goto cleanup;
    }
    if (PAPI_start(EventSet) != PAPI_OK)
        goto cleanup;
    if (PAPI_stop(EventSet, values) == PAPI_OK) {
        total_supported++;
        if (nsupported < MAX_SUPPORTED_COMBOS) {
            unsigned int m = 0;
            for (int i = 0; i < COMBO_SIZE; i++) {
                supported_idxs[nsupported][i] = idx[i];
                m |= 1U << idx[i];
            }
            supported_masks[nsupported++] = m;
        }
        printf("[SUPPORTED] ");
        print_combo(idx);
    }

cleanup:
    PAPI_cleanup_eventset(EventSet);
    PAPI_destroy_eventset(&EventSet);
}

static void generate(int offset, int k, int idx[COMBO_SIZE]) {
    if (k == 0) {
        test_one(idx);
        return;
    }
    for (int i = offset; i <= NEVENTS - k; i++) {
        idx[COMBO_SIZE - k] = i;
        generate(i + 1, k - 1, idx);
    }
}

int main(void) {
    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) {
        fprintf(stderr, "PAPI init error\n");
        return EXIT_FAILURE;
    }
    for (int i = 0; i < NEVENTS; i++) {
        if (PAPI_event_name_to_code((char*)event_names[i], &event_codes[i]) != PAPI_OK) {
            fprintf(stderr, "Unknown event %s\n", event_names[i]);
            return EXIT_FAILURE;
        }
    }

    int idx[COMBO_SIZE];
    generate(0, COMBO_SIZE, idx);

    printf("\nTested %lld combos, %lld supported (%.1f%%)\n\n",
           total_tested, total_supported,
           100.0 * total_supported / total_tested);

    const unsigned int ALL_MASK = (1U << NEVENTS) - 1;
    unsigned int covered = 0;
    int target = (NEVENTS + COMBO_SIZE - 1) / COMBO_SIZE;
    int cover_order[MAX_SUPPORTED_COMBOS];
    int cover_sz = 0;

    while (covered != ALL_MASK) {
        int best_i = -1, best_new = 0;
        for (int i = 0; i < nsupported; i++) {
            unsigned int new_bits = supported_masks[i] & ~covered;
            int cnt = __builtin_popcount(new_bits);
            if (cnt > best_new) {
                best_new = cnt;
                best_i = i;
            }
        }
        if (best_i < 0) break;
        cover_order[cover_sz++] = best_i;
        covered |= supported_masks[best_i];
    }

    if (covered != ALL_MASK) {
        printf("❌ Unable to cover all %d events with any supported 5-combos.\n", NEVENTS);
    } else {
        if (cover_sz > target) {
            printf("⚠️  No cover of size %d exists; using greedy cover of size %d:\n\n", target, cover_sz);
        } else {
            printf("✅ Found a cover of size %d (theoretical min %d):\n\n", cover_sz, target);
        }
	printf("[");
        for (int i = 0; i < cover_sz; i++) {
            print_combo(supported_idxs[cover_order[i]]);
        }
	printf("]");
    }
    return EXIT_SUCCESS;
}

