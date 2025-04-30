#include <stdio.h>

// Declare the assembly functions with correct return types
extern unsigned long SimMagic0(unsigned long cmd);
extern unsigned long SimMagic2(unsigned long cmd, unsigned long arg0, unsigned long arg1);

// Define the commands (these values come from sim_api.h)
#define SIM_CMD_ROI_START       1
#define SIM_CMD_ROI_END         2
#define SIM_CMD_PROC_ID         9

int main() {
    SimMagic0(SIM_CMD_ROI_START);
    printf("Process ID: %lu\n", SimMagic0(SIM_CMD_PROC_ID));
    SimMagic0(SIM_CMD_ROI_END);
    return 0;
}