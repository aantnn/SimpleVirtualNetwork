#ifndef VPNANDROIDHELPERS_H
#define VPNANDROIDHELPERS_H
#include <stdio.h>
#include <stdlib.h>
extern int   __attribute__((weak)) AndroidLog(const char* format, ...);
extern void  __attribute__((weak)) AndroidPause();
extern char* __attribute__((weak)) GetAndroidDbDir();
extern char* __attribute__((weak)) GetAndroidLogDir();
extern char* __attribute__((weak)) GetAndroidTmpDir();

static int (*original_fputs)(const char *, FILE *) = fputs;
#define fputs(str, stream) \
    do { \
        if ((stream) == stdout || (stream) == stderr) { \
            AndroidLog("%s", str); \
        } else { \
            original_fputs(str, stream); \
        } \
    } while (0)
#endif
