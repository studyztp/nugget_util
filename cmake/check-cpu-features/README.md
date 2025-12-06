By running `check-cpu-features`, it outputs the LLVM LLC accepted command line that should include all features the current host has.

For example: 
```
-mcpu=neoverse-n1 -mtriple=aarch64-unknown-linux-gnu -mattr="+fp-armv8,+lse,+neon,+crc,+crypto"
```

Be careful when using this with a simulator, as not all modern instructions are supported. 
For example, gem5 does not support AVX. 
If your simulator falls into this category, make sure to remove the feature here. 
You can disable a feature using a minus sign, for example: ```-mattr="-avx"```
