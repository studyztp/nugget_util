ARCH=$(uname -m)
mkdir -p libpfm
git clone https://git.code.sf.net/p/perfmon2/libpfm4 libpfm/$ARCH
cd libpfm/$ARCH
make
