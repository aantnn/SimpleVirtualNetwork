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


if(CMAKE_HOST_WIN32)
    string(REPLACE "C:/" "/cygdrive/c/" ANDROID_NDK_CYGWIN "${ANDROID_NDK}")
endif ()

include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)

set(openssl_configure_flags
        ${OPENSSL_TARGET}
        -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}
        -fPIC shared no-ui no-ui-console no-engine no-filenames)

set(OPENSSL_CONFIGURE_COMMAND
        cd "<SOURCE_DIR>" &&
        ${CMAKE_COMMAND} -E env  ${ENV_SCRIPT_CMD} perl "<SOURCE_DIR>/Configure" ${openssl_configure_flags}
        "--prefix=<INSTALL_DIR>")
set(OPENSSL_BUILD_COMMAND
        ${CMAKE_COMMAND} -E env  ${ENV_SCRIPT_CMD} make -j${NPROC} -sC "<SOURCE_DIR>" build_libs)
set(OPENSSL_INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env  ${ENV_SCRIPT_CMD} make -j${NPROC} -sC "<SOURCE_DIR>" install_dev install_runtime)


#BUILD_IN_SOURCE 1 SO COPY
if (DEFINED OPENSSL_SOURCE_DIR AND EXISTS ${OPENSSL_SOURCE_DIR})
    set(OPENSSL_DST_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src/openssl")
    message(STATUS "Superbuild ExternalProject: BUILD_IN_SOURCE 1
 Copy from: ${OPENSSL_SOURCE_DIR}
 To: ${OPENSSL_DST_SRC_DIR}/..")
    file(COPY "${OPENSSL_SOURCE_DIR}" DESTINATION "${OPENSSL_DST_SRC_DIR}/..") # The /.. is for overwriting the same dir name
    ExternalProject_Add(openssl
            SOURCE_DIR ${OPENSSL_DST_SRC_DIR}
            PREFIX ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
            BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
            INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
            DOWNLOAD_COMMAND ""
            BUILD_BYPRODUCTS <INSTALL_DIR>/include/openssl/openssl.h <INSTALL_DIR>/lib/libcrypto.so <INSTALL_DIR>/lib/libssl.so
    )
else ()
    ExternalProject_Add(openssl
            URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
            URL_HASH SHA256=${OPENSSL_SHA_VER}
            PREFIX ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
            BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
            INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
            DOWNLOAD_EXTRACT_TIMESTAMP 0
            BUILD_BYPRODUCTS <INSTALL_DIR>/include/openssl/openssl.h <INSTALL_DIR>/lib/libcrypto.so <INSTALL_DIR>/lib/libssl.so
    )
endif ()
ExternalProject_Get_Property(openssl INSTALL_DIR)
#ExternalProject_Get_Property(openssl SOURCE_DIR)

set(OPENSSL_CRYPTO_LIBRARY "${INSTALL_DIR}/lib/libcrypto.so")
set(OPENSSL_SSL_LIBRARY "${INSTALL_DIR}/lib/libssl.so")
set(OPENSSL_INSTALL_PREFIX "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")

message(WARNING "Generating headers due to CMake and Ninja build system limitations in External build prioritization https://discourse.cmake.org/t/design-cmake-projects-with-autocode-generators/9011/2")
set(openssl_configure_flags
        perl ./Configure
        ${OPENSSL_TARGET}
        --prefix=${OPENSSL_INSTALL_PREFIX}
        -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}
        -fPIC shared no-ui no-ui-console no-engine no-filenames)
build_autoconf_external_project(openssl "${OPENSSL_DST_SRC_DIR}" "" "${openssl_configure_flags}" "build_generated" "build_generated" "")
file(COPY "${OPENSSL_DST_SRC_DIR}/include/openssl" DESTINATION "${INSTALL_DIR}/include/")
file(COPY "${OPENSSL_DST_SRC_DIR}/include/crypto" DESTINATION "${INSTALL_DIR}/include/")
# Ninja does not respect byproducts with headers. It behaves like they already there

set(OPENSSL_INCLUDE_DIR "${INSTALL_DIR}/include")


file(MAKE_DIRECTORY ${INSTALL_DIR}/include)

set(OPENSSL_DIR ${INSTALL_DIR} CACHE INTERNAL "")

add_library(OpenSSL::Crypto UNKNOWN IMPORTED)
add_dependencies(OpenSSL::Crypto openssl)
set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "C"
        INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/libcrypto.so")

add_library(OpenSSL::SSL UNKNOWN IMPORTED)
add_dependencies(OpenSSL::SSL openssl)
set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "C"
        #INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
        INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/libssl.so")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenSSL
        REQUIRED_VARS OPENSSL_SSL_LIBRARY OPENSSL_CRYPTO_LIBRARY OPENSSL_INCLUDE_DIR
)


#[[function(get_current_stack_targets output_var)
    get_property(targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
    set(${output_var} ${targets} PARENT_SCOPE)
endfunction()

function(add_dependency_to_stack_targets )
    get_current_stack_targets(TARGETS)
    foreach(target ${TARGETS})
        if ("${target}" STREQUAL "openssl")
            message(FATAL_ERROR "Something wrong happened. Cannot add target openssl to openssl target\nSTACK:${stack}\n")
        endif()
        target_link_libraries(${target} PRIVATE  OpenSSL::Crypto)
        add_dependencies(${target} OpenSSL::Crypto)
    endforeach()
endfunction()

function(watch_deprecated_stack_usage var access value current_list_file stack)
    if(access STREQUAL "READ_ACCESS")
        message(DEPRECATION "The variable '${var}' is deprecated! Use OpenSSL::Crypto")
        add_dependency_to_stack_targets(${stack})
    endif()
endfunction()
variable_watch(OPENSSL_CRYPTO_LIBRARY watch_deprecated_stack_usage)

add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/external/include/header1.h
        COMMAND ${CMAKE_COMMAND} --build . --target MyExternalProject
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
add_custom_target(GenerateHeaders DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/external/include/header1.h)
add_dependencies(MyMainProject GenerateHeaders)]]
