if [ "$#" -eq 0 ]; then
    echo "Error: missing PAPI install prefix." >&2
    echo "Usage: $0 <papi_prefix_dir>" >&2
    exit 1
fi

if [ "$#" -gt 1 ]; then
    echo "Error: too many arguments; expected only the PAPI install prefix." >&2
    echo "Usage: $0 <papi_prefix_dir>" >&2
    exit 1
fi

papi_prefix="$1"

if [ ! -d "$papi_prefix" ]; then
    echo "Error: directory '$papi_prefix' does not exist." >&2
    exit 1
fi

gcc -O2 -std=c99 \
    -I"$papi_prefix"/include \
    -L"$papi_prefix"/lib \
    test_papi_combos.c \
    -o test_papi_combos \
    -lpapi
