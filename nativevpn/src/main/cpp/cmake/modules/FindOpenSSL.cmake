# OpenSSL Android Build Integration Module
#
# This module provides:
# - Dependency management helpers:
#     get_current_stack_targets()
#     add_dependency_to_stack_targets()
#     watch_deprecated_stack_usage()
#   to integrate OpenSSL into the build graph and track variable usage
#
# - Android ABI-specific OpenSSL target configuration via:
#     get_openssl_target()
#
# - Platform-specific environment setup for build commands (Windows/Unix)
#
# - Configuration of OpenSSL build flags for cross-compilation on Android
#
# - ExternalProject-based build, install, and import of OpenSSL libraries

include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)

function(handle_dependency_trigger VAR ACCESS VALUE CURRENT_FILE STACK)
    if(ACCESS STREQUAL "READ_ACCESS")
        force_global_dependency(openssl)
    endif()
endfunction()

variable_watch(OPENSSL_CRYPTO_LIBRARY handle_dependency_trigger)
variable_watch(OPENSSL_SSL_LIBRARY handle_dependency_trigger)
variable_watch(OPENSSL_INCLUDE_DIR handle_dependency_trigger)
variable_watch(OPENSSL_INSTALL_PREFIX handle_dependency_trigger)

find_path(OPENSSL_INCLUDE_DIR openssl.h)
find_library(OPENSSL_SSL_LIBRARY OpenSSL::SSL)
find_library(OPENSSL_CRYPTO_LIBRARY OpenSSL::Crypto)
mark_as_advanced(OPENSSL_INCLUDE_DIR OpenSSL_LIBRARY)


if (OPENSSL_FOUND OR TARGET OpenSSL::Crypto)
    return()
endif ()



set(OPENSSL_VERSION $ENV{OPENSSL_VERSION})
set(OPENSSL_SHA_VER "$ENV{OPENSSL_SHA}")

function(get_openssl_target out_var)
    if (ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${out_var} "android-arm" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "arm64-v8a")
        set(${out_var} "android-arm64" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "x86")
        set(${out_var} "android-x86" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "x86_64")
        set(${out_var} "android-x86_64" PARENT_SCOPE)
    endif ()
endfunction()

get_openssl_target(OPENSSL_TARGET)


get_autoconf_target(AUTOCONF_TARGET)


string(REPLACE "\\" "/" INSTALL_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
if (CMAKE_HOST_WIN32)
    set(ENV_SCRIPT_CMD ${CMAKE_BINARY_DIR}/openssl_configure_env.bat)
    set(ANDROID_NDK_BACK ${ANDROID_NDK})
    string(REPLACE "C:/" "/cygdrive/c/" ANDROID_NDK "${ANDROID_NDK}")
    create_env_file(${ENV_SCRIPT_CMD} ${CYGWIN_BIN_DIR})
    set(ANDROID_NDK ${ANDROID_NDK_BACK})
else ()
    set(ENV_SCRIPT_CMD ${CMAKE_BINARY_DIR}/openssl_configure_env.sh)
    create_env_file(${ENV_SCRIPT_CMD} "")
endif ()


set(openssl_configure_flags
        ${OPENSSL_TARGET}
        -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}
        -fPIC shared no-ui no-ui-console no-engine no-filenames)

set(OPENSSL_CONFIGURE_COMMAND
        cd "<SOURCE_DIR>" &&
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} perl "<SOURCE_DIR>/Configure" ${openssl_configure_flags}
        "--prefix=${INSTALL_DIR}")
set(OPENSSL_BUILD_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make "-j${NPROC}" -sC "<SOURCE_DIR>" build_libs)
set(OPENSSL_INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make "-j${NPROC}" -sC "<SOURCE_DIR>" install_dev install_runtime)


add_external_project(
        PROJECT_NAME openssl
        SOURCE_DIR "${OPENSSL_SOURCE_DIR}"
        VERSION "${OPENSSL_VERSION}"
        URL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
        SHA256 "${OPENSSL_SHA_VER}"
        INSTALL_DIR "${INSTALL_DIR}"
        CONFIGURE_COMMAND "${OPENSSL_CONFIGURE_COMMAND}"
        BUILD_COMMAND "${OPENSSL_BUILD_COMMAND}"
        INSTALL_COMMAND "${OPENSSL_INSTALL_COMMAND}"
        BUILD_BYPRODUCTS
        "${INSTALL_DIR}/lib/libssl.so"
        "${INSTALL_DIR}/lib/libcrypto.so"
)

#ExternalProject_Get_Property(openssl INSTALL_DIR)
#string(REPLACE "\\" "/" OPENSSL_INSTALL_DIR ${INSTALL_DIR})

add_library(OpenSSL::SSL SHARED IMPORTED)
add_library(OpenSSL::Crypto SHARED IMPORTED)

set(OPENSSL_INCLUDE_DIR "${INSTALL_DIR}/include")
file(MAKE_DIRECTORY ${OPENSSL_INCLUDE_DIR})

set(OPENSSL_INSTALL_PREFIX "${INSTALL_DIR}")
set(OPENSSL_CRYPTO_LIBRARY "${INSTALL_DIR}/lib/libcrypto.so")
set(OPENSSL_SSL_LIBRARY "${INSTALL_DIR}/lib/libssl.so")

set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_SSL_LIBRARY}
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}"
)
set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION ${OPENSSL_CRYPTO_LIBRARY}
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}"
)
add_dependencies(OpenSSL::SSL openssl)
add_dependencies(OpenSSL::Crypto openssl)




