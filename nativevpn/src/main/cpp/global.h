#ifndef MYVPNCLIENTGLOBAL_H
#define MYVPNCLIENTGLOBAL_H

#include <jni.h>
#include <pthread.h>

extern pthread_rwlock_t g_config_rwlock;
struct vpn_global_config {
    // JNI environment pointer (valid only when attached to Java thread)
    JNIEnv* jni_env;

    // Global reference to the Java VPN service object
    jobject thiz_java_vpn_service;

    // Path to temporary directory (owned by this struct)
    char* temporary_dir_path;

    // Path to log directory (owned by this struct)
    char* log_dir_path;

    // Path to database directory (owned by this struct)
    char* database_dir_path;

};

typedef struct {
    char* temporary_dir;
    char* log_dir;
    char* database_dir;
    jobject context;     // Global reference to Context
    JavaVM* jvm;        // Cached JavaVM pointer
} VpnConfig;

extern VpnConfig g_config;

//extern struct vpn_global_config g_vpn_config;
#define TAG "NativeVpn"

#endif
