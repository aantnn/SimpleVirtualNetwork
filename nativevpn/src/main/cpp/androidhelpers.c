#include "include/androidhelpers.h"
#include <stdlib.h>
#include <string.h>
#include <android/log.h>
#include <stdarg.h>
#include "global.h"
#include <stdlib.h>
#include <pthread.h>


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

extern char* GetAndroidLogDir() {
    char* result = NULL;
    if (pthread_rwlock_rdlock(&g_config_rwlock) == 0) {
        if (g_vpn_config.log_dir_path) {
            result = strdup(g_vpn_config.log_dir_path);
        }
        pthread_rwlock_unlock(&g_config_rwlock);
    }
    return result;
}

extern char* GetAndroidTmpDir() {
    char* result = NULL;
    if (pthread_rwlock_rdlock(&g_config_rwlock) == 0) {
        if (g_vpn_config.temporary_dir_path) {
            result = strdup(g_vpn_config.temporary_dir_path);
        }
        pthread_rwlock_unlock(&g_config_rwlock);
    }
    return result;
}

extern char* GetAndroidDbDir() {
    char* result = NULL;
    if (pthread_rwlock_rdlock(&g_config_rwlock) == 0) {
        if (g_vpn_config.database_dir_path) {
            result = strdup(g_vpn_config.database_dir_path);
        }
        pthread_rwlock_unlock(&g_config_rwlock);
    }
    return result;
}