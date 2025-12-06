// test_papi_combos.c
#define _GNU_SOURCE 1
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <limits.h>
#include <papi.h>

#define SUPPORTED_INIT_CAP 1024
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static int combo_size = 1;
static char **event_names = NULL;
static int nevents = 0;
static int *event_codes = NULL;

static int  supported_cap = 0;
static int  nsupported = 0;
static int *supported_idxs = NULL;     // flattened [nsupported][combo_size]
static unsigned int *supported_masks = NULL;

static long long *values = NULL;
static long long total_tested = 0, total_supported = 0;

static char *dupstr(const char *s) {
    size_t len = strlen(s) + 1;
    char *p = malloc(len);
    if (p) memcpy(p, s, len);
    return p;
}

static bool add_event_name(const char *name) {
    char **tmp = realloc(event_names, (nevents + 1) * sizeof(*event_names));
    if (!tmp) return false;
    event_names = tmp;
    event_names[nevents] = dupstr(name);
    if (!event_names[nevents]) return false;
    nevents++;
    return true;
}

static bool ensure_supported_capacity(void) {
    if (nsupported < supported_cap) return true;
    int new_cap = supported_cap ? supported_cap * 2 : SUPPORTED_INIT_CAP;
    unsigned int *new_masks = realloc(supported_masks, new_cap * sizeof(*new_masks));
    int *new_idxs = realloc(supported_idxs, new_cap * combo_size * sizeof(*new_idxs));
    if (!new_masks || !new_idxs) {
        free(new_masks);
        free(new_idxs);
        return false;
    }
    supported_masks = new_masks;
    supported_idxs = new_idxs;
    supported_cap = new_cap;
    return true;
}

static void print_combo(const int idx[]) {
    printf("[");
    for (int i = 0; i < combo_size; i++) {
        printf("'%s%s", event_names[idx[i]], (i + 1 < combo_size ? "', " : "],\n"));
    }
}

static void test_one(int idx[]) {
    int EventSet = PAPI_NULL;
    total_tested++;

    if (PAPI_create_eventset(&EventSet) != PAPI_OK)
        return;
    for (int i = 0; i < combo_size; i++) {
        if (PAPI_add_event(EventSet, event_codes[idx[i]]) != PAPI_OK)
            goto cleanup;
    }
    if (PAPI_start(EventSet) != PAPI_OK)
        goto cleanup;
    if (PAPI_stop(EventSet, values) == PAPI_OK) {
        total_supported++;
        if (ensure_supported_capacity()) {
            unsigned int m = 0;
            int *dst = &supported_idxs[nsupported * combo_size];
            for (int i = 0; i < combo_size; i++) {
                dst[i] = idx[i];
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

static void generate(int offset, int k, int idx[]) {
    if (k == 0) {
        test_one(idx);
        return;
    }
    for (int i = offset; i <= nevents - k; i++) {
        idx[combo_size - k] = i;
        generate(i + 1, k - 1, idx);
    }
}

static bool parse_papi_avail(const char *path) {
    if (access(path, X_OK) != 0) {
        perror("Cannot execute papi_avail");
        return false;
    }

    size_t cmd_len = strlen(path) + 4; // space + "-a" + null
    char *cmd = malloc(cmd_len + 1);
    if (!cmd) {
        fprintf(stderr, "Allocation failure building command string.\n");
        return false;
    }
    snprintf(cmd, cmd_len + 1, "%s -a", path);

    FILE *pipe = popen(cmd, "r");
    free(cmd);
    if (!pipe) {
        perror("popen");
        return false;
    }

    char *line = NULL;
    size_t cap = 0;
    char name[128];
    bool ok = true;
    while (ok && getline(&line, &cap, pipe) != -1) {
        if (sscanf(line, "%127s", name) == 1 && strncmp(name, "PAPI_", 5) == 0) {
            if (nevents >= 32) {
                fprintf(stderr, "Skipping remaining events after 32 to avoid mask overflow.\n");
                continue;
            }
            if (!add_event_name(name)) {
                fprintf(stderr, "Out of memory while collecting events\n");
                ok = false;
            }
        }
    }
    free(line);
    if (pclose(pipe) == -1) {
        perror("pclose");
        return false;
    }
    return ok && nevents > 0;
}

static void free_events(void) {
    for (int i = 0; i < nevents; i++) free(event_names[i]);
    free(event_names);
    free(event_codes);
    free(values);
    free(supported_masks);
    free(supported_idxs);
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <combo_size> <path_to_papi_avail>\n", argv[0]);
        return EXIT_FAILURE;
    }

    char *end = NULL;
    long parsed = strtol(argv[1], &end, 10);
    if (end == argv[1] || *end != '\0' || parsed <= 0 || parsed > INT_MAX) {
        fprintf(stderr, "Invalid combo size: %s\n", argv[1]);
        return EXIT_FAILURE;
    }
    combo_size = (int)parsed;

    const char *papi_path = argv[2];
    if (!papi_path || *papi_path == '\0') {
        fprintf(stderr, "Invalid path to papi_avail.\n");
        return EXIT_FAILURE;
    }

    if (!parse_papi_avail(papi_path)) {
        fprintf(stderr, "Could not obtain events from papi_avail.\n");
        free_events();
        return EXIT_FAILURE;
    }

    if (nevents == 0) {
        fprintf(stderr, "No events found from papi_avail.\n");
        free_events();
        return EXIT_FAILURE;
    }

    if (combo_size > nevents) {
        fprintf(stderr, "Combo size (%d) exceeds number of events (%d).\n", combo_size, nevents);
        free_events();
        return EXIT_FAILURE;
    }

    event_codes = calloc(nevents, sizeof(*event_codes));
    values = calloc(combo_size, sizeof(*values));
    if (!event_codes || !values) {
        fprintf(stderr, "Allocation failure.\n");
        free_events();
        return EXIT_FAILURE;
    }

    if (PAPI_library_init(PAPI_VER_CURRENT) != PAPI_VER_CURRENT) {
        fprintf(stderr, "PAPI init error\n");
        free_events();
        return EXIT_FAILURE;
    }
    for (int i = 0; i < nevents; i++) {
        if (PAPI_event_name_to_code((char*)event_names[i], &event_codes[i]) != PAPI_OK) {
            fprintf(stderr, "Unknown event %s\n", event_names[i]);
            free_events();
            return EXIT_FAILURE;
        }
    }

    int *idx = calloc(combo_size, sizeof(*idx));
    if (!idx) {
        fprintf(stderr, "Allocation failure.\n");
        free_events();
        return EXIT_FAILURE;
    }

    generate(0, combo_size, idx);

    printf("\nTested %lld combos, %lld supported (%.1f%%)\n\n",
           total_tested, total_supported,
           total_tested ? 100.0 * total_supported / total_tested : 0.0);

    const unsigned int ALL_MASK = (nevents == 32) ? 0xFFFFFFFFu : ((1U << nevents) - 1U);

    unsigned int covered = 0;
    int target = (nevents + combo_size - 1) / combo_size;
    int *cover_order = calloc(nsupported, sizeof(*cover_order));
    if (!cover_order) {
        fprintf(stderr, "Allocation failure.\n");
        free(idx);
        free_events();
        return EXIT_FAILURE;
    }
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
        printf("Unable to cover all %d events with any supported %d-combos.\n", nevents, combo_size);
    } else {
        if (cover_sz > target) {
            printf("Greedy cover size %d (minimum possible %d unknown).\n\n", cover_sz, target);
        } else {
            printf("Found a cover of size %d (theoretical min %d):\n\n", cover_sz, target);
        }
        printf("[");
        for (int i = 0; i < cover_sz; i++) {
            print_combo(&supported_idxs[cover_order[i] * combo_size]);
        }
        printf("]\n");
    }

    free(cover_order);
    free(idx);
    free_events();
    return EXIT_SUCCESS;
}

