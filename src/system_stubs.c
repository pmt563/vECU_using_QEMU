// src/system_stubs.c
// Stubs cần thiết khi dùng -nostartfiles + rdimon

void SystemInit(void) {}   // nếu startup.s có bl SystemInit

// newlib gọi qua __libc_init_array => cần _init/_fini
void _init(void) {}
void _fini(void) {}
