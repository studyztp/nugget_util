#include "dr_api.h"
#include "drmgr.h"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

#define SYS_TRACKING_START 888
#define SYS_TRACKING_STOP  889

static app_pc pc0 = NULL, pc1 = NULL, pc2 = NULL;
static int threshold0 = 0, threshold1 = 0, threshold2 = 0;
static int count0 = 0, count1 = 0, count2 = 0;
static uint64 instr_since_last_dump = 0;

enum Phase { PHASE0, PHASE1, PHASE2, PHASE_DONE };
static enum Phase current_phase = PHASE0;

static bool tracking_enabled = false;

static void on_instruction(void);
static void on_hit_pc0(void);
static void on_hit_pc1(void);
static void on_hit_pc2(void);
static void event_exit(void);
static dr_emit_flags_t event_bb_instrumentation(void *, void *, instrlist_t *, instr_t *, bool, bool, void *);
static bool syscall_event(void *drcontext, int sysnum);

DR_EXPORT void 
dr_client_main(client_id_t id, int argc, const char *argv[])
{
    dr_set_client_name("PC Tracker", "https://dynamorio.org");

    if (argc < 12) {
        dr_fprintf(STDERR, "Usage: -pc0 <addr> -t0 <val> -pc1 <addr> -t1 <val> -pc2 <addr> -t2 <val>\n");
        return;
    }

    for (int i = 0; i < argc - 1; ++i) {
        if (strcmp(argv[i], "-pc0") == 0)
            pc0 = (app_pc)(uintptr_t)strtoull(argv[++i], NULL, 0);
        else if (strcmp(argv[i], "-t0") == 0)
            threshold0 = atoi(argv[++i]);
        else if (strcmp(argv[i], "-pc1") == 0)
            pc1 = (app_pc)(uintptr_t)strtoull(argv[++i], NULL, 0);
        else if (strcmp(argv[i], "-t1") == 0)
            threshold1 = atoi(argv[++i]);
        else if (strcmp(argv[i], "-pc2") == 0)
            pc2 = (app_pc)(uintptr_t)strtoull(argv[++i], NULL, 0);
        else if (strcmp(argv[i], "-t2") == 0)
            threshold2 = atoi(argv[++i]);
    }

    drmgr_init();
    dr_register_exit_event(event_exit);
    drmgr_register_bb_instrumentation_event(NULL, event_bb_instrumentation, NULL);
    drmgr_register_pre_syscall_event(syscall_event);
}

static void
event_exit(void)
{
    dr_fprintf(STDERR, "Final state:\n");
    dr_fprintf(STDERR, "PC0 hits: %d\n", count0);
    dr_fprintf(STDERR, "PC1 hits: %d\n", count1);
    dr_fprintf(STDERR, "PC2 hits: %d\n", count2);

    drmgr_unregister_pre_syscall_event(syscall_event);
    drmgr_unregister_bb_instrumentation_event(event_bb_instrumentation);
    drmgr_exit();
}

static bool
syscall_event(void *drcontext, int sysnum)
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

static void on_instruction(void)
{
    if (tracking_enabled && current_phase != PHASE_DONE)
        instr_since_last_dump++;
}

static void on_hit_pc0(void)
{
    if (tracking_enabled && current_phase == PHASE0 && ++count0 >= threshold0) {
        dr_fprintf(STDERR, "[PC0 threshold reached] Instructions: %llu\n", instr_since_last_dump);
        instr_since_last_dump = 0;
        current_phase = PHASE1;
    }
}

static void on_hit_pc1(void)
{
    if (tracking_enabled && current_phase == PHASE1 && ++count1 >= threshold1) {
        dr_fprintf(STDERR, "[PC1 threshold reached] Instructions: %llu\n", instr_since_last_dump);
        instr_since_last_dump = 0;
        current_phase = PHASE2;
    }
}

static void on_hit_pc2(void)
{
    if (tracking_enabled && current_phase == PHASE2 && ++count2 >= threshold2) {
        dr_fprintf(STDERR, "[PC2 threshold reached] Instructions: %llu\n", instr_since_last_dump);
        current_phase = PHASE_DONE;
    }
}

static dr_emit_flags_t
event_bb_instrumentation(void *drcontext, void *tag, instrlist_t *bb,
                         instr_t *instr, bool for_trace, bool translating,
                         void *user_data)
{   
    if (translating)
        return DR_EMIT_DEFAULT;

    if (!drmgr_is_first_instr(drcontext, instr))
        return DR_EMIT_DEFAULT;

    for (instr_t *i = instrlist_first_app(bb); i != NULL; i = instr_get_next_app(i)) {
        app_pc pc = instr_get_app_pc(i);
        if (pc == NULL)
            continue;

        dr_insert_clean_call(drcontext, bb, i, (void *)on_instruction, false, 0);
        if (pc == pc0)
            dr_insert_clean_call(drcontext, bb, i, (void *)on_hit_pc0, false, 0);
        else if (pc == pc1)
            dr_insert_clean_call(drcontext, bb, i, (void *)on_hit_pc1, false, 0);
        else if (pc == pc2)
            dr_insert_clean_call(drcontext, bb, i, (void *)on_hit_pc2, false, 0);
    }

    return DR_EMIT_DEFAULT;
}
