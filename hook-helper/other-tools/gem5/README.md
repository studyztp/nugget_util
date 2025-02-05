# Create M5OP library
For information about gem5 m5ops, please see the [gem5 M5OP Documentation](https://www.gem5.org/documentation/general_docs/m5ops/).

This directory helps creating the m5ops needed for annotating workloads for gem5 simulation.


# Instruction
1. Make sure you have the compilers needed if you want to cross compile
2. Run `ISA="[isa1] [isa2]" ./get-gem5-util.sh`

It will create the directories:
- include: all the header files needed for m5ops
- [isa]: it has the m5op libraries
