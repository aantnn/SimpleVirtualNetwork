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

function(get_current_stack_targets output_var)
    get_property(targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
    set(${output_var} ${targets} PARENT_SCOPE)
endfunction()

function(add_dependency_to_stack_targets)
    get_current_stack_targets(TARGETS)
    foreach (target ${TARGETS})
        if ("${target}" STREQUAL "openssl" OR "${target}" STREQUAL "copy-openssl")
            #message(WARNING "Something wrong happened. Cannot add target openssl to openssl target\nSTACK:${stack}\n")
            continue()
        endif ()
        #message(WARNING "TARGET ${target}")
        add_dependencies(${target} openssl)
    endforeach ()
endfunction()

function(watch_deprecated_stack_usage var access value current_list_file stack)
    if (access STREQUAL "READ_ACCESS")
        add_dependency_to_stack_targets(${stack})
    endif ()
endfunction()

variable_watch(OPENSSL_CRYPTO_LIBRARY watch_deprecated_stack_usage)
variable_watch(OPENSSL_SSL_LIBRARY watch_deprecated_stack_usage)
variable_watch(OPENSSL_INCLUDE_DIR watch_deprecated_stack_usage)
variable_watch(OPENSSL_INSTALL_PREFIX watch_deprecated_stack_usage)

find_path(OPENSSL_INCLUDE_DIR openssl.h)
find_library(OPENSSL_SSL_LIBRARY OpenSSL::SSL)
find_library(OPENSSL_CRYPTO_LIBRARY OpenSSL::Crypto)
mark_as_advanced(OPENSSL_INCLUDE_DIR OpenSSL_LIBRARY)


if (OPENSSL_FOUND OR TARGET OpenSSL::Crypto)
    return()
endif ()

include(ExternalProject)

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

include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
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

if (DEFINED OPENSSL_SOURCE_DIR AND EXISTS ${OPENSSL_SOURCE_DIR})
    set(OPENSSL_DST_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src/openssl")
    #file(COPY "${OPENSSL_SOURCE_DIR}" DESTINATION "${OPENSSL_DST_SRC_DIR}/..") # The /.. is for overwriting the same dir name
    add_custom_command(
            OUTPUT "${OPENSSL_DST_SRC_DIR}/Configure"
            COMMAND ${CMAKE_COMMAND} -E make_directory "${OPENSSL_DST_SRC_DIR}"
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${OPENSSL_SOURCE_DIR}"
            "${OPENSSL_DST_SRC_DIR}"
            COMMENT "Copying OpenSSL sources"
    )
    add_custom_target(copy-openssl DEPENDS "${OPENSSL_DST_SRC_DIR}/Configure")
    ExternalProject_Add(openssl
            SOURCE_DIR ${OPENSSL_DST_SRC_DIR}
            PREFIX ${INSTALL_DIR}
            DEPENDS copy-openssl
            CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
            BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
            INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
            DOWNLOAD_COMMAND ""
            BUILD_BYPRODUCTS
            ${INSTALL_DIR}/lib/libssl.so
            ${INSTALL_DIR}/lib/libcrypto.so
            BUILD_IN_SOURCE 1
    )
else ()
    ExternalProject_Add(openssl
            URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
            URL_HASH SHA256=${OPENSSL_SHA_VER}
            PREFIX ${INSTALL_DIR}
            CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
            BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
            INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
            DOWNLOAD_EXTRACT_TIMESTAMP 0
            BUILD_BYPRODUCTS
            ${INSTALL_DIR}/lib/libssl.so
            ${INSTALL_DIR}/lib/libcrypto.so
            BUILD_IN_SOURCE 1
    )
endif ()


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




