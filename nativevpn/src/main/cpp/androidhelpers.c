#include "include/androidhelpers.h"
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
#include <stdarg.h>
#include "global.h"


extern int AndroidLog(const char* format, ...) {
    va_list args;
    va_start(args, format);
    int result = __android_log_vprint(ANDROID_LOG_INFO, TAG, format, args);
    va_end(args);
    return result;
}

/*extern void AndroidPause() {
    // Simple pause implementation
    //pause();
}*/

extern char* GetAndroidDbDir() {
    return g_vpn_config.database_dir_path ? strdup(g_vpn_config.database_dir_path) : NULL;
}

extern char* GetAndroidLogDir() {
    return g_vpn_config.log_dir_path ? strdup(g_vpn_config.log_dir_path) : NULL;
}

extern char* GetAndroidTmpDir() {
    return g_vpn_config.temporary_dir_path ? strdup(g_vpn_config.temporary_dir_path) : NULL;
}
