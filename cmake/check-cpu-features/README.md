By running `check-cpu-features`, it outputs the LLVM LLC accepted command line that should include all features the current host has.

For example: 
```
-mcpu=neoverse-n1 -mtriple=aarch64-unknown-linux-gnu -mattr="+fp-armv8,+lse,+neon,+crc,+crypto"
```

Be careful when using this with simulator, because not all modern instructions are supported by simulators.
For example, there are many simulators do not support AVX. 
If this is the case for your simulator, make sure to remove the feature from here.
You can remove a feature with the minus sign, for example: ```-mattr="-avx"```.
