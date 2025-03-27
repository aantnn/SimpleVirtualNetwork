#ifndef MYVPNCLIENTGLOBAL_H
#define MYVPNCLIENTGLOBAL_H

#include <jni.h>

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

extern struct vpn_global_config g_vpn_config;
#define TAG "NativeVpn"

#endif
