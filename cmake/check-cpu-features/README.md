By running `check-cpu-features`, it outputs the LLVM LLC accepted command line that should include all features the current host has.

For example: 
```
-mcpu=neoverse-n1 -mtriple=aarch64-unknown-linux-gnu -mattr="+fp-armv8,+lse,+neon,+crc,+crypto"
```