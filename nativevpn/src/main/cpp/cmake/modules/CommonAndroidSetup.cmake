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




function(log_error error command args dir )
    string(REPLACE ";" "\ " command_print "${command}")
    string(REPLACE ";" "\ " args_print "${args}")
    message(FATAL_ERROR "Build failed:
${dir}
Command: ${command_print} ${args_print}
OUTPUT [EXTERNAL]:
${error}
[EOF]")
endfunction()


function(build_external target src_dir)
    message(STATUS "Building external project:
 ${target}
 At: ${src_dir} ")
    set(trigger_build_dir "${src_dir}")
    # Generate a batch file to handle the PATH properly
    #"${CMAKE_BINARY_DIR}/configure_env.bat"
    set(CMAKE_LIST_CONTENT "
        cmake_minimum_required(VERSION 3.22.1)
        project(${target})
        include(ExternalProject)
        ExternalProject_add( ${target}
    ${ARGN} )
        add_custom_target(trigger_${target})
        add_dependencies(trigger_${target} ${target})
    ")
    file(WRITE "${trigger_build_dir}/CMakeLists.txt" "${CMAKE_LIST_CONTENT}")

    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS} .
            WORKING_DIRECTORY ${trigger_build_dir}
            OUTPUT_VARIABLE cmd_output
            RESULT_VARIABLE result
            ERROR_VARIABLE error
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
    )
    if(NOT result EQUAL "0")
        log_error("${cmd_output} ${error}" "${CMAKE_COMMAND}" "${CMAKE_ARGS}" "${trigger_build_dir}")
    endif()
    message("Configure [EXTERNAL]
${cmd_output}\n[EOF]")

    execute_process(COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY ${trigger_build_dir}
            OUTPUT_VARIABLE cmd_output
            RESULT_VARIABLE result
            ERROR_VARIABLE error
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
    )
    if(NOT result EQUAL "0")
        log_error("${cmd_output} ${error}" "${CMAKE_COMMAND}" "--build ." "${trigger_build_dir}")
    endif()
    message("Build [EXTERNAL]
${cmd_output}\n[EOF]")
endfunction()




function(build_autoconf_external_project project source_dir env configure_cmd build_args install_args cmake_args )
    #set(AUTOCONF_CURRENT_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/external/${project}")
    set(AUTOCONF_CURRENT_BUILD_DIR "${source_dir}")
    set(SUPER_BUILD_DIR ${AUTOCONF_CURRENT_BUILD_DIR} PARENT_SCOPE)
    set(CMAKE_ARGS
            -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
            -DCMAKE_EXPORT_COMPILE_COMMANDS=${CMAKE_EXPORT_COMPILE_COMMANDS}
            -DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}
            -DANDROID_PLATFORM=${ANDROID_PLATFORM}
            -DANDROID_ABI=${ANDROID_ABI}
            -DCMAKE_ANDROID_ARCH_ABI=${CMAKE_ANDROID_ARCH_ABI}
            -DANDROID_NDK=${ANDROID_NDK}
            -DCMAKE_ANDROID_NDK=${CMAKE_ANDROID_NDK}
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
            -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
            -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -B${AUTOCONF_CURRENT_BUILD_DIR}
            -G${CMAKE_GENERATOR}
            #-DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}"

    )
    if (CMAKE_HOST_WIN32) #fix "slashes"
        string(REPLACE "\\" "/" CMAKE_ARGS "${CMAKE_ARGS}")
    endif ()
#[[
    message(STATUS "Superbuild ExternalProject: BUILD_IN_SOURCE 1
 Copy from: ${source_dir}
 To: ${AUTOCONF_CURRENT_BUILD_DIR}")
    file(COPY "${source_dir}" DESTINATION "${AUTOCONF_CURRENT_BUILD_DIR}/..")
]]


    build_external(
            "${project}_${ANDROID_ABI}"
            ${AUTOCONF_CURRENT_BUILD_DIR}
            " SOURCE_DIR        ${AUTOCONF_CURRENT_BUILD_DIR} "
            " BUILD_IN_SOURCE 1 "
            " CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} ${configure_cmd}"
            " BUILD_COMMAND     ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make -j${NPROC} ${build_args} "
            " INSTALL_COMMAND   ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make -j${NPROC} ${install_args} "
            " CMAKE_ARGS        ${CMAKE_ARGS} "
    )
endfunction()