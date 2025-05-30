gcc -O2 -std=c99 \
    -I$1/include \
    -L$1/lib \
    test_papi_combos.c \
    -o test_papi_combos \
    -lpapi
