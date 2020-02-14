#include "test.h"

uintptr_t invoke(fn_usize func, void *args) {
    return func(args);
}
