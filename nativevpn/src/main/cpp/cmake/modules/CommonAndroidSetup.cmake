function(get_autoconf_target autoconf_target)
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(${autoconf_target} "aarch64-linux-android" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${autoconf_target} "armv7a-linux-androideabi" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86")
        set(${autoconf_target} "i686-linux-android" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(${autoconf_target} "x86_64-linux-android" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unsupported ABI: ${ANDROID_ABI}")
    endif()
endfunction()

get_autoconf_target(AUTOCONF_TARGET)





function(create_env_file ENV_SCRIPT_CMD A_PATH)
if(CMAKE_HOST_WIN32)
    set(ENV_SETTER "set")
else ()
    set(ENV_SETTER "export")
endif()
set(android_env "") 
string(APPEND android_env "${ENV_SETTER} CC=${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang\n")
string(APPEND android_env "${ENV_SETTER} AR=llvm-ar\n")
string(APPEND android_env "${ENV_SETTER} AS=${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang\n")
string(APPEND android_env "${ENV_SETTER} CXX=${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang++\n")
string(APPEND android_env "${ENV_SETTER} LD=ld\n")
string(APPEND android_env "${ENV_SETTER} RANLIB=llvm-ranlib\n")
string(APPEND android_env "${ENV_SETTER} STRIP=llvm-strip\n")
if(CMAKE_HOST_WIN32)
    string(APPEND android_env "${ENV_SETTER} ANDROID_NDK_ROOT=${ANDROID_NDK}\n")
    string(APPEND android_env "${ENV_SETTER} PATH=${ANDROID_TOOLCHAIN_ROOT}/bin;${A_PATH};$ENV{PATH}\n")
else ()
    string(APPEND android_env "${ENV_SETTER} ANDROID_NDK_ROOT=${ANDROID_NDK}\n")
    string(APPEND android_env "${ENV_SETTER} PATH=\"${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}\"\n")
endif()

# The %PATH% semicolon issue in ExternalProject_Add is particularly stubborn on Windows so
# Determine host platform and create appropriate environment script
if(CMAKE_HOST_WIN32)
    file(WRITE ${ENV_SCRIPT_CMD}
"@echo off
setlocal enabledelayedexpansion
${android_env}
${CMAKE_COMMAND} -E env %*" )
else()
    file(WRITE ${ENV_SCRIPT_CMD}
"#!/bin/bash
${android_env}
${CMAKE_COMMAND} -E env $@
exit $?")
    execute_process(COMMAND chmod +x ${ENV_SCRIPT_CMD})
endif()
endfunction()


