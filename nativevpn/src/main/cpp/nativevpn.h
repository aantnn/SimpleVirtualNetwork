//
// Created by a on 19/02/2024.
//
#ifndef SIMPLEVPN_LIBEXECVPNCLIENT_H
#define SIMPLEVPN_LIBEXECVPNCLIENT_H

#include "global.h"
#include <android/log.h>
#include <jni.h>
#define MALLOC_ERROR "Memory allocation failed"

#define ERROR_LOG(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
#define DEBUG_LOG(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

extern int VpnClientMain(int argc, char *argv[]);
JNIEXPORT jstring JNICALL
Java_ru_valishin_nativevpn_NativeVpn_getLogDirectory(JNIEnv *env, jobject thiz);

// Function declarations for camelCase functions
extern jboolean getGlobalConfigString(char **output, const char *source);
static jboolean updateGlobalConfig(char **config_field, JNIEnv *env,
                                   jobject vpn_service, jstring new_value);
static int cleanupGlobalConfig(JNIEnv *env);

#endif // SIMPLEVPN_LIBEXECVPNCLIENT_H
