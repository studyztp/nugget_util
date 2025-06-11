#include "dr_api.h"
#include "drmgr.h"
#include <string.h>
#include "dr_ir_instr.h"
#include <inttypes.h> 
#include <stdlib.h>    /* for strtoull() */

#define MAX_MARKERS 3

/* Up to MAX_MARKERS PCs to watch; initialized to NULL here. */
static app_pc marker_pcs[MAX_MARKERS] = { NULL, NULL, NULL };
static uint64_t marker_count[MAX_MARKERS] = { 0 };
static bool tracking_enabled = false;
static file_t log_file;

#define SYS_TRACKING_START 888
#define SYS_TRACKING_STOP  889

static void event_exit(void);
static dr_emit_flags_t event_bb_instrumentation(void *drcontext, void *tag,
                                                instrlist_t *bb, instr_t *instr,
                                                bool for_trace, bool translating,
                                                void *user_data);
static void marker_hit(int marker_index);
static bool pre_syscall(void *drcontext, int sysnum);

/* 
 * Helper: print simple usage message.
 * You can expand this if you want more detailed help.
 */
static void
print_usage(void)
{
    dr_printf(
        "Marker Tracker (modern)\n"
        "  Usage: -pc <hexadecimal-address> [-pc <hexadecimal-address>] [-pc <hexadecimal-address>]\n"
        "  e.g.: drrun -- /path/to/your_client.so -pc 0x401270 -pc 0x401280 -pc 0x4012F0\n"
        "  At most %d PCs may be specified; any extra are ignored.\n",
        MAX_MARKERS);
}

/* Entry point: parse up to three “-pc 0x...” arguments. */
DR_EXPORT void
dr_client_main(client_id_t id, int argc, const char *argv[])
{
    dr_set_client_name("Marker Tracker (modern)", "https://dynamorio.org");

    /* Initialize drmgr (required for register_bb_instrumentation, etc.) */
    if (!drmgr_init()) {
        DR_ASSERT(false);
        return;
    }

    /* Register the events we care about. */
    dr_register_exit_event(event_exit);
    drmgr_register_pre_syscall_event(pre_syscall);
    drmgr_register_bb_instrumentation_event(NULL, event_bb_instrumentation, NULL);

    /* 
     * Parse command‐line arguments. We expect zero to three occurrences of:
     *   -pc <hex-address>
     * If the user passes fewer than MAX_MARKERS,
     * any remaining marker_pcs[i] stay as NULL.
     */
    int pc_index = 0;
    for (int i = 1; i < argc && pc_index < MAX_MARKERS; i++) {
        if (strcmp(argv[i], "-pc") == 0) {
            if (i + 1 < argc) {
                const char *hexstr = argv[i + 1];
                /* strtoull with base-16: skip the “0x” if present or just parse */
                app_pc pc = (app_pc)strtoull(hexstr, NULL, 16);
                if (pc == 0) {
                    /* Parsing failed (e.g. “0xZZZ” or missing “0x”)? print a warning. */
                    dr_printf("Warning: could not parse address '%s'\n", hexstr);
                } else {
                    marker_pcs[pc_index++] = pc;
                    dr_printf("Configured marker[%d] = %p\n", pc_index - 1, pc);
                }
                i++; /* skip the hex token we just consumed */
            } else {
                /* Missing argument after -pc */
                dr_printf("Error: '-pc' requires a hexadecimal argument.\n");
                print_usage();
                /* We’ll just bail out; you could also choose to continue with defaults. */
                dr_abort(); 
            }
        }
        /* else: ignore any other flags */
    }

    /* If the user gave no -pc at all, show usage and exit. */
    if (pc_index == 0) {
        dr_printf("Error: no '-pc' arguments provided.\n");
        print_usage();
        dr_abort();
    }
    /* Any slots from pc_index..(MAX_MARKERS-1) remain NULL, which is fine. */

    dr_log(NULL, DR_LOG_ALL, 1, "Marker Tracker initialized\n");
    dr_printf("Marker Tracker initialized (tracking %d marker(s))\n", pc_index);

    /* Open a log file. */
    log_file = dr_open_file("marker_log.txt",
                            DR_FILE_WRITE_APPEND | DR_FILE_ALLOW_LARGE);
    DR_ASSERT_MSG(log_file != INVALID_FILE, "Could not open marker_log.txt\n");
    dr_log(NULL, DR_LOG_ALL, 1, "Logging to marker_log.txt\n");
}


/* 
 * At exit, print counts for each non‐NULL marker_pcs[i].
 */
static void
event_exit(void)
{
    for (int i = 0; i < MAX_MARKERS; i++) {
        if (marker_pcs[i] != NULL) {
            dr_fprintf(STDERR,
                       "Marker at %p executed %" PRIu64 " times\n",
                       marker_pcs[i], marker_count[i]);
        }
    }
    drmgr_unregister_pre_syscall_event(pre_syscall);
    drmgr_unregister_bb_instrumentation_event(event_bb_instrumentation);
    // dr_unregister_bb_event(event_bb_instrumentation);
    drmgr_exit();
}


/* Called via clean‐call when a marker PC is hit in a basic block. */
static void
marker_hit(int marker_index)
{
    if (tracking_enabled && marker_index >= 0 && marker_index < MAX_MARKERS) {
        marker_count[marker_index]++;
        dr_fprintf(log_file, "%d->", marker_index);
    }
}

/*
 * For each basic block, check if its first instruction's PC matches one of
 * our configured marker_pcs[]. If so, insert a clean call to marker_hit().
 */
static dr_emit_flags_t
event_bb_instrumentation(void *drcontext, void *tag, instrlist_t *bb,
                         instr_t *instr, bool for_trace, bool translating,
                         void *user_data)
{
    /* Don’t instrument while DynamoRIO is still translating the block */
    if (translating)
        return DR_EMIT_DEFAULT;

    /* If we’re not tracking, skip instrumentation. */
    if (!drmgr_is_first_instr(drcontext, instr))
        return DR_EMIT_DEFAULT;

    /* Now we know we’re in the “post‐translate” pass, so each BB
       is only visited once. */
    for (instr_t *i = instrlist_first_app(bb); i != NULL;
         i = instr_get_next_app(i)) {
        app_pc pc = instr_get_app_pc(i);
        if (pc == NULL)
            continue;

        for (int j = 0; j < MAX_MARKERS; j++) {
            if (marker_pcs[j] != NULL && pc == marker_pcs[j]) {
                dr_insert_clean_call(
                    drcontext, bb, i, (void *)marker_hit, false, 1,
                    OPND_CREATE_INT32(j)); /* Pass the marker index as an argument */
                dr_printf("Inserted clean call for marker[%d] at PC %p\n", j, pc);
                break;
            }
        }
    }
    return DR_EMIT_DEFAULT;
}

/*
 * Toggle tracking_enabled on/off when the app does our special syscalls:
 * SYS_TRACKING_START (888) turns it on; SYS_TRACKING_STOP (889) turns it off.
 */
static bool
pre_syscall(void *drcontext, int sysnum)
{
    if (sysnum == SYS_TRACKING_START) {
        tracking_enabled = true;
        dr_printf("Received syscall %d — tracking enabled\n", SYS_TRACKING_START);
    } else if (sysnum == SYS_TRACKING_STOP) {
        tracking_enabled = false;
        dr_printf("Received syscall %d — tracking disabled\n", SYS_TRACKING_STOP);
    }
    return true; /* Continue executing the syscall normally */
}
