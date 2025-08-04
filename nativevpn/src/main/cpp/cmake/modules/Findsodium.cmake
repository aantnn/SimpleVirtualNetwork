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
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make "-j${NPROC}" -sC "<SOURCE_DIR>" install)
set(INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make "-j${NPROC}" -sC "<SOURCE_DIR>" install)


add_external_project(
        PROJECT_NAME libsodium
        SOURCE_DIR "${SODIUM_SOURCE_DIR}"
        VERSION "${SODIUM_VERSION}"
        URL "https://github.com/jedisct1/libsodium/archive/refs/tags/${SODIUM_VERSION}.tar.gz"
        SHA256 "${SODIUM_SHA}"
        INSTALL_DIR "${INSTALL_DIR}"
        CONFIGURE_COMMAND "${CONFIGURE_COMMAND}"
        BUILD_COMMAND "${BUILD_COMMAND}"
        INSTALL_COMMAND "${INSTALL_COMMAND}"
        BUILD_BYPRODUCTS
            ${INSTALL_DIR}/lib/libsodium.so
            ${INSTALL_DIR}/include/sodium.h
)

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

function(handle_dependency_trigger VAR ACCESS VALUE CURRENT_FILE STACK)
    if(ACCESS STREQUAL "READ_ACCESS")
        force_global_dependency(libsodium)
    endif()
endfunction()
variable_watch(SODIUM_INCLUDE_DIRS handle_dependency_trigger)
variable_watch(SODIUM_LIBRARIES handle_dependency_trigger)
variable_watch(SODIUM_LINK_LIBRARIES handle_dependency_trigger)
