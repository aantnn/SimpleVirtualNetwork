include(ExternalProject)
if (SODIUM_FOUND OR TARGET sodium)
    return()
endif ()
set(SODIUM_SHA $ENV{SODIUM_SHA})
set(SODIUM_VERSION $ENV{SODIUM_VERSION})


include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)


string(REPLACE "\\" "/" INSTALL_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
if(CMAKE_HOST_WIN32)
    set (ENV_SCRIPT_CMD ${CMAKE_BINARY_DIR}/configure_env.bat)
    create_env_file(${ENV_SCRIPT_CMD} ${MSYS_BIN_DIR})
else()
    set (ENV_SCRIPT_CMD ${CMAKE_BINARY_DIR}/configure_env.sh)
    create_env_file(${ENV_SCRIPT_CMD} "")
endif()

set(configure_flags
        --host=${AUTOCONF_TARGET})

if (ANDROID_ABI STREQUAL "arm64-v8a")
    list(APPEND configure_command ${configure_command} CFLAGS=-march=armv8-a+crypto+aes)
endif ()



set(CONFIGURE_COMMAND
        cd "<SOURCE_DIR>" &&
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} bash "<SOURCE_DIR>/configure" ${configure_flags}
        "--prefix=${INSTALL_DIR}" "--enable-shared" "--disable-static")
set(BUILD_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make -j${NPROC} -sC "<SOURCE_DIR>" install)
set(INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make -j${NPROC} -sC "<SOURCE_DIR>" install)


if (DEFINED SODIUM_SOURCE_DIR AND EXISTS ${SODIUM_SOURCE_DIR})
    set(COPY_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src/libsodium/")
    #message(STATUS "NECESSARY Copy of sources. Reason: BUILD_IN_SOURCE 1 ExternalProject(libsodium")
    #file(COPY "${SODIUM_SOURCE_DIR}" DESTINATION "${COPY_SRC_DIR}/..")
    add_custom_command(
        OUTPUT "${COPY_SRC_DIR}/Configure"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${COPY_SRC_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${SODIUM_SOURCE_DIR}"
            "${COPY_SRC_DIR}"
        COMMENT "Copying libsodium sources"
    )
    add_custom_target(copy-libsodium DEPENDS "${COPY_SRC_DIR}/Configure")
    ExternalProject_Add(libsodium
            SOURCE_DIR ${COPY_SRC_DIR}
            PREFIX ${INSTALL_DIR}
            DEPENDS copy-libsodium
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_COMMAND ""
            BUILD_BYPRODUCTS ${INSTALL_DIR}/lib/libsodium.so  ${INSTALL_DIR}/include/sodium.h
            BUILD_IN_SOURCE 1
    )
else ()
    ExternalProject_Add(libsodium
            URL https://github.com/jedisct1/libsodium/archive/refs/tags/${SODIUM_VERSION}.tar.gz
            URL_HASH SHA256=${SODIUM_SHA}
            PREFIX ${INSTALL_DIR}
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_EXTRACT_TIMESTAMP 0
            BUILD_BYPRODUCTS ${INSTALL_DIR}/lib/libsodium.so  ${INSTALL_DIR}/include/sodium.h
            BUILD_IN_SOURCE 1
    )
endif ()
#ExternalProject_Get_Property(libsodium INSTALL_DIR)
#ExternalProject_Get_Property(libsodium SOURCE_DIR)
#string(REPLACE "\\" "/" INSTALL_DIR ${INSTALL_DIR})

file(MAKE_DIRECTORY ${INSTALL_DIR}/include)

add_library(sodium UNKNOWN IMPORTED)
add_dependencies(sodium libsodium)
set_target_properties(sodium PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "C"
        INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/libsodium.so")

# Mark as found for ExternalProject
#for pkg_search_module
set(SODIUM_INCLUDE_DIRS ${INSTALL_DIR}/include CACHE INTERNAL "")
set(SODIUM_LIBRARIES ${INSTALL_DIR}/lib/libsodium.so CACHE INTERNAL "")
set(SODIUM_LINK_LIBRARIES ${INSTALL_DIR}/lib/libsodium.so CACHE INTERNAL "")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(sodium
        REQUIRED_VARS SODIUM_INCLUDE_DIRS SODIUM_LIBRARIES SODIUM_LINK_LIBRARIES
)



function(get_current_stack_targets output_var)
    get_property(targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
    set(${output_var} ${targets} PARENT_SCOPE)
endfunction()

function(add_dependency_to_stack_targets )
    get_current_stack_targets(TARGETS)
    foreach(target ${TARGETS})
        if ("${target}" STREQUAL "libsodium" OR "${target}" STREQUAL "copy-libsodium")
            #message(WARNING "Something wrong happened. Cannot add target openssl to openssl target\nSTACK:${stack}\n")
            continue()
        endif()
        add_dependencies(${target} libsodium)
    endforeach()
endfunction()

function(watch_deprecated_stack_usage var access value current_list_file stack)
    if(access STREQUAL "READ_ACCESS")
        add_dependency_to_stack_targets(${stack})
    endif()
endfunction()
variable_watch(SODIUM_INCLUDE_DIRS watch_deprecated_stack_usage)
variable_watch(SODIUM_LIBRARIES watch_deprecated_stack_usage)
variable_watch(SODIUM_LINK_LIBRARIES watch_deprecated_stack_usage)
