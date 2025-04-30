#ifndef __SIM_API
#define __SIM_API

// Command definitions
#define SIM_CMD_ROI_TOGGLE      0  // Deprecated, for compatibility with programs compiled long ago
#define SIM_CMD_ROI_START       1
#define SIM_CMD_ROI_END         2
#define SIM_CMD_MHZ_SET         3
#define SIM_CMD_MARKER          4
#define SIM_CMD_USER            5
#define SIM_CMD_INSTRUMENT_MODE 6
#define SIM_CMD_MHZ_GET         7
#define SIM_CMD_IN_SIMULATOR    8
#define SIM_CMD_PROC_ID         9
#define SIM_CMD_THREAD_ID       10
#define SIM_CMD_NUM_PROCS       11
#define SIM_CMD_NUM_THREADS     12
#define SIM_CMD_NAMED_MARKER    13
#define SIM_CMD_SET_THREAD_NAME 14

#define SIM_OPT_INSTRUMENT_DETAILED    0
#define SIM_OPT_INSTRUMENT_WARMUP      1
#define SIM_OPT_INSTRUMENT_FASTFORWARD 2

// Low-level magic functions
unsigned long SimMagic0(unsigned long cmd);
unsigned long SimMagic1(unsigned long cmd, unsigned long arg0);
unsigned long SimMagic2(unsigned long cmd, unsigned long arg0, unsigned long arg1);

// High-level interface functions
void SimRoiStart(void);
void SimRoiEnd(void);
unsigned long SimGetProcId(void);
unsigned long SimGetThreadId(void);
void SimSetThreadName(const char* name);
unsigned long SimGetNumProcs(void);
unsigned long SimGetNumThreads(void);
void SimSetFreqMHz(unsigned long proc, unsigned long mhz);
void SimSetOwnFreqMHz(unsigned long mhz);
unsigned long SimGetFreqMHz(unsigned long proc);
unsigned long SimGetOwnFreqMHz(void);
void SimMarker(unsigned long arg0, unsigned long arg1);
void SimNamedMarker(unsigned long arg0, const char* str);
void SimUser(unsigned long cmd, unsigned long arg);
void SimSetInstrumentMode(unsigned long opt);
int SimInSimulator(void);

#endif /* __SIM_API */