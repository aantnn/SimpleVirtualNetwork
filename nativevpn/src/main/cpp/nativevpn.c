#include "nativevpn.h"
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <pthread.h>
#include "global.h"

#define NATIVE_VPN_JNI_VERSION JNI_VERSION_1_6
#define NATIVE_VPN_ERR_MEMORY "Memory allocation failed"
#define NATIVE_VPN_ERR_INVALID "Invalid parameters"
#define NATIVE_VPN_ERR_STRDUP "String duplication failed"
#define NATIVE_VPN_ERR_LOCK "Lock operation failed"

// Read-write lock for thread-safe access to shared configuration
pthread_rwlock_t g_config_rwlock = PTHREAD_RWLOCK_INITIALIZER;

static inline int vpn_client_entrypoint(int argc, char *argv[]) {
    return VpnClientMain(argc, argv);
}

struct vpn_global_config g_vpn_config = {0};

static int cleanup_global_config(JNIEnv *env) {
    if (pthread_rwlock_wrlock(&g_config_rwlock) != 0) {
        ERROR_LOG(NATIVE_VPN_ERR_LOCK);
        return -1;
    }

    if (g_vpn_config.thiz_java_vpn_service) {
        (*env)->DeleteGlobalRef(env, g_vpn_config.thiz_java_vpn_service);
        g_vpn_config.thiz_java_vpn_service = NULL;
    }

    free(g_vpn_config.temporary_dir_path);
    g_vpn_config.temporary_dir_path = NULL;

    free(g_vpn_config.log_dir_path);
    g_vpn_config.log_dir_path = NULL;

    free(g_vpn_config.database_dir_path);
    g_vpn_config.database_dir_path = NULL;

    g_vpn_config.jni_env = NULL;

    pthread_rwlock_unlock(&g_config_rwlock);
    return 0;
}

extern jboolean get_global_config_string(char **output, const char *source) {
    if (pthread_rwlock_rdlock(&g_config_rwlock) != 0) {
        ERROR_LOG(NATIVE_VPN_ERR_LOCK);
        return JNI_FALSE;
    }

    if (source) {
        *output = strdup(source);
        pthread_rwlock_unlock(&g_config_rwlock);
        return *output ? JNI_TRUE : JNI_FALSE;
    }

    pthread_rwlock_unlock(&g_config_rwlock);
    return JNI_FALSE;
}

static jboolean update_global_config(char **config_field,
                                     JNIEnv *env,
                                     jobject vpn_service,
                                     jstring new_value) {
    if (!config_field || !env || !vpn_service || !new_value) {
        ERROR_LOG(NATIVE_VPN_ERR_INVALID);
        return JNI_FALSE;
    }

    const char *native_str = (*env)->GetStringUTFChars(env, new_value, NULL);
    if (!native_str) {
        ERROR_LOG("Failed to convert Java string");
        return JNI_FALSE;
    }

    char *value_copy = strdup(native_str);
    (*env)->ReleaseStringUTFChars(env, new_value, native_str);

    if (!value_copy) {
        ERROR_LOG(NATIVE_VPN_ERR_STRDUP);
        return JNI_FALSE;
    }

    if (pthread_rwlock_wrlock(&g_config_rwlock) != 0) {
        ERROR_LOG(NATIVE_VPN_ERR_LOCK);
        free(value_copy);
        return JNI_FALSE;
    }

    // Replace existing value
    free(*config_field);
    *config_field = value_copy;

    // Initialize global reference if needed
    if (!g_vpn_config.thiz_java_vpn_service) {
        g_vpn_config.jni_env = env;
        jobject global_ref = (*env)->NewGlobalRef(env, vpn_service);
        if (!global_ref) {
            ERROR_LOG("Failed to create global reference");
            free(value_copy);
            *config_field = NULL;
            pthread_rwlock_unlock(&g_config_rwlock);
            return JNI_FALSE;
        }
        g_vpn_config.thiz_java_vpn_service = global_ref;
    }

    pthread_rwlock_unlock(&g_config_rwlock);
    return JNI_TRUE;
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_closeFileDescriptor(
        JNIEnv *env, jobject thiz, jint file_descriptor) {
    (void)env; (void)thiz; // Unused parameters

    if (file_descriptor >= 0) {
        close(file_descriptor);
    }
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_nativeStartVpnClient(
        JNIEnv *env, jobject thiz, jobjectArray arguments) {
    (void)thiz; // Unused parameter

    if (!env || !arguments) {
        ERROR_LOG(NATIVE_VPN_ERR_INVALID);
        return;
    }

    jsize arg_count = (*env)->GetArrayLength(env, arguments);
    if (arg_count <= 0) {
        ERROR_LOG("Empty arguments array");
        return;
    }

    char **arg_vector = calloc(arg_count + 1, sizeof(char *));
    if (!arg_vector) {
        ERROR_LOG(NATIVE_VPN_ERR_MEMORY);
        return;
    }

    jboolean success = JNI_TRUE;

    for (jsize i = 0; i < arg_count && success; i++) {
        jstring arg = (jstring)(*env)->GetObjectArrayElement(env, arguments, i);
        if (!arg) {
            success = JNI_FALSE;
            continue;
        }

        const char *native_arg = (*env)->GetStringUTFChars(env, arg, NULL);
        if (!native_arg) {
            (*env)->DeleteLocalRef(env, arg);
            success = JNI_FALSE;
            continue;
        }

        arg_vector[i] = strdup(native_arg);
        (*env)->ReleaseStringUTFChars(env, arg, native_arg);
        (*env)->DeleteLocalRef(env, arg);

        if (!arg_vector[i]) {
            ERROR_LOG(NATIVE_VPN_ERR_STRDUP);
            success = JNI_FALSE;
        }
    }

    if (!success) {
        for (jsize j = 0; j < arg_count && arg_vector[j]; j++) {
            free(arg_vector[j]);
        }
        free(arg_vector);
        return;
    }

    int result = vpn_client_entrypoint(arg_count, arg_vector);

    for (jsize i = 0; i < arg_count; i++) {
        free(arg_vector[i]);
    }
    free(arg_vector);
}

JNIEXPORT jstring JNICALL
Java_ru_valishin_nativevpn_NativeVpn_getLogDirectory(
        JNIEnv *env, jobject thiz) {
    char *log_dir = NULL;
    if (!get_global_config_string(&log_dir, g_vpn_config.log_dir_path)) {
        return NULL;
    }

    jstring result = (*env)->NewStringUTF(env, log_dir);
    free(log_dir);
    return result;
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setLogDirectory(
        JNIEnv *env, jobject thiz, jstring new_log_dir) {
    if (!update_global_config(&g_vpn_config.log_dir_path,
                              env, thiz, new_log_dir)) {
        ERROR_LOG("Failed to set log directory");
    }
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setDatabaseDirectory(
        JNIEnv *env, jobject thiz, jstring new_db_dir) {
    if (!update_global_config(&g_vpn_config.database_dir_path,
                              env, thiz, new_db_dir)) {
        ERROR_LOG("Failed to set database directory");
    }
}

JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    return NATIVE_VPN_JNI_VERSION;
}

JNIEXPORT void JNICALL
JNI_OnUnload(JavaVM *vm, void *reserved) {
    (void)reserved;

    JNIEnv *env;
    if ((*vm)->GetEnv(vm, (void **)&env, NATIVE_VPN_JNI_VERSION) == JNI_OK) {
        if (cleanup_global_config(env) != 0) {
            ERROR_LOG("Failed to cleanup global config");
        }
    }
    pthread_rwlock_destroy(&g_config_rwlock);
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setTemporaryDirectory(
        JNIEnv *env, jobject thiz, jstring new_temp_dir) {
    if (!update_global_config(&g_vpn_config.temporary_dir_path,
                              env, thiz, new_temp_dir)) {
        ERROR_LOG("Failed to set temporary directory");
    }
}