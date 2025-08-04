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


function(compute_directory_hash dir output_var)
    if(NOT EXISTS "${dir}")
        set(${output_var} "not_found" PARENT_SCOPE)
        return()
    endif()

    file(GLOB_RECURSE all_files RELATIVE "${dir}" "${dir}/*")
    unset(hash_input)
    foreach(file IN LISTS all_files)
        get_filename_component(filepath "${dir}/${file}" ABSOLUTE)
        if(EXISTS "${filepath}")
            file(SIZE "${filepath}" file_size)
            file(TIMESTAMP "${filepath}" file_time "%Y-%m-%d %H:%M:%S" UTC)
            string(APPEND hash_input "${file}|${file_size}|${file_time}\n")
        endif()
    endforeach()

    string(SHA256 dir_hash "${hash_input}")
    set(${output_var} "${dir_hash}" PARENT_SCOPE)
endfunction()

function(check_source_hash_changed source_dir hash_file result_var)
    compute_directory_hash("${source_dir}" CURRENT_SOURCE_HASH)
    set(${result_var} FALSE PARENT_SCOPE)

    if(NOT EXISTS "${hash_file}")
        set(${result_var} TRUE PARENT_SCOPE)
        file(WRITE "${hash_file}" "${CURRENT_SOURCE_HASH}")
    else()
        file(READ "${hash_file}" OLD_SOURCE_HASH)
        string(STRIP "${OLD_SOURCE_HASH}" OLD_SOURCE_HASH)
        string(STRIP "${CURRENT_SOURCE_HASH}" CURRENT_SOURCE_HASH)

        if(NOT OLD_SOURCE_HASH STREQUAL CURRENT_SOURCE_HASH)
            set(${result_var} TRUE PARENT_SCOPE)
            file(WRITE "${hash_file}" "${CURRENT_SOURCE_HASH}")
        endif()
    endif()
endfunction()

function(add_source_copy_target_and_copy
        target_name
        source_dir
        dest_dir
        force_copy
        comment_prefix
)
    if(force_copy)
        add_custom_command(
                OUTPUT "${dest_dir}/.source_copy_done"
                COMMAND ${CMAKE_COMMAND} -E remove_directory "${dest_dir}"
                COMMAND ${CMAKE_COMMAND} -E make_directory "${dest_dir}"
                COMMAND ${CMAKE_COMMAND} -E copy_directory "${source_dir}" "${dest_dir}"
                COMMAND ${CMAKE_COMMAND} -E touch "${dest_dir}/.source_copy_done"
                COMMENT "${comment_prefix} - Copying sources..."
                VERBATIM
        )
    else()
        add_custom_command(
                OUTPUT "${dest_dir}/.source_copy_done"
                COMMAND ${CMAKE_COMMAND} -E echo "${dest_dir}/.source_copy_done"
                COMMENT "${comment_prefix} - Sources unchanged, skipping copy."
                VERBATIM
        )
    endif()

    add_custom_target(${target_name}
            DEPENDS "${dest_dir}/.source_copy_done"
    )
endfunction()