#include <stdint.h>

typedef uintptr_t (*fn_usize)(void*);

uintptr_t invoke(fn_usize func, void *args);
