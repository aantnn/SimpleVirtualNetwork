#include <jni.h>
#include <android/log.h>
#include <string.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#include "nativevpn.h"
#define TAG "NativeVpn"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)

static inline int vpnClientEntrypoint(int argc, char *argv[]) {
    return VpnClientMain(argc, argv);
}
// Global state protection
pthread_rwlock_t g_config_rwlock = PTHREAD_RWLOCK_INITIALIZER;

// Global configuration structure
VpnConfig  g_config = {0};

// Forward declarations
static jboolean setDirectory(JNIEnv* env, const char** target, jstring path);
static void freeConfig(JNIEnv* env);
static JNIEnv* getJNIEnv(void);

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    (void)reserved;
    g_config.jvm = vm;
    return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL JNI_OnUnload(JavaVM* vm, void* reserved) {
    (void)vm;
    (void)reserved;

    JNIEnv* env = getJNIEnv();
    if (env) {
        freeConfig(env);
    }
    pthread_rwlock_destroy(&g_config_rwlock);
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_closeFd(JNIEnv* env, jobject thiz, jint fd) {
    (void)env;
    (void)thiz;

    if (fd >= 0) {
        close(fd);
    }
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setTemporaryDirectory(JNIEnv* env, jobject thiz, jstring dir) {
    (void)thiz;
    pthread_rwlock_wrlock(&g_config_rwlock);
    if (!setDirectory(env, &g_config.temporary_dir, dir)) {
        LOGE("Failed to set temporary directory");
    }
    pthread_rwlock_unlock(&g_config_rwlock);
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setLogDirectory(JNIEnv* env, jobject thiz, jstring dir) {
    (void)thiz;
    pthread_rwlock_wrlock(&g_config_rwlock);
    if (!setDirectory(env, &g_config.log_dir, dir)) {
        LOGE("Failed to set log directory");
    }
    pthread_rwlock_unlock(&g_config_rwlock);
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_setDatabaseDirectory(JNIEnv* env, jobject thiz, jstring dir) {
    (void)thiz;
    pthread_rwlock_wrlock(&g_config_rwlock);
    if (!setDirectory(env, &g_config.database_dir, dir)) {
        LOGE("Failed to set database directory");
    }
    pthread_rwlock_unlock(&g_config_rwlock);
}

JNIEXPORT void JNICALL
Java_ru_valishin_nativevpn_NativeVpn_nativeStartVpnClient(JNIEnv* env, jobject thiz, jobjectArray args) {
    (void)thiz;

    if (!env || !args) {
        LOGE("Invalid parameters passed to nativeStartVpnClient");
        return;
    }

    jsize arg_count = (*env)->GetArrayLength(env, args);
    if (arg_count <= 0) {
        LOGE("No arguments provided");
        return;
    }

    // Allocate array for arguments
    char** argv = calloc(arg_count + 1, sizeof(char*));
    if (!argv) {
        LOGE("Memory allocation failed for argument array");
        return;
    }

    // Convert Java string array to C strings
    jboolean success = JNI_TRUE;
    for (jsize i = 0; i < arg_count && success; i++) {
        jstring arg = (*env)->GetObjectArrayElement(env, args, i);
        if (!arg) {
            success = JNI_FALSE;
            continue;
        }

        const char* str = (*env)->GetStringUTFChars(env, arg, NULL);
        if (!str) {
            success = JNI_FALSE;
        } else {
            argv[i] = strdup(str);
            (*env)->ReleaseStringUTFChars(env, arg, str);

            if (!argv[i]) {
                success = JNI_FALSE;
            }
        }
        (*env)->DeleteLocalRef(env, arg);
    }

    // Start VPN if argument conversion was successful
    if (success) {
        // TODO: Implement actual VPN client start
        // vpn_client_start(arg_count, argv);
        LOGI("Starting VPN client with %d arguments", arg_count);
        int result = vpnClientEntrypoint(arg_count, argv);
    }

    // Cleanup
    for (jsize i = 0; i < arg_count; i++) {
        free(argv[i]);
    }
    free(argv);
}

// Helper functions
static jboolean setDirectory(JNIEnv* env, const char** target, jstring path) {
    if (!env || !target || !path) {
        return JNI_FALSE;
    }

    const char* native_path = (*env)->GetStringUTFChars(env, path, NULL);
    if (!native_path) {
        return JNI_FALSE;
    }

    char* new_path = strdup(native_path);
    (*env)->ReleaseStringUTFChars(env, path, native_path);

    if (!new_path) {
        return JNI_FALSE;
    }

    free((void*)*target);
    *target = new_path;
    return JNI_TRUE;
}

static void freeConfig(JNIEnv* env) {
    pthread_rwlock_wrlock(&g_config_rwlock);

    free(g_config.temporary_dir);
    free(g_config.log_dir);
    free(g_config.database_dir);

    if (g_config.context) {
        (*env)->DeleteGlobalRef(env, g_config.context);
    }

    memset(&g_config, 0, sizeof(g_config));

    pthread_rwlock_unlock(&g_config_rwlock);
}

static JNIEnv* getJNIEnv(void) {
    if (!g_config.jvm) {
        return NULL;
    }

    JNIEnv* env = NULL;
    jint result = (*g_config.jvm)->GetEnv(g_config.jvm, (void**)&env, JNI_VERSION_1_6);

    if (result == JNI_EDETACHED) {
        if ((*g_config.jvm)->AttachCurrentThread(g_config.jvm, &env, NULL) != JNI_OK) {
            return NULL;
        }
    }

    return env;
}