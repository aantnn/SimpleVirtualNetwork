include(ExternalProject)
if (TARGET iconv)
    return()
endif ()
set(ICONV_VERSION $ENV{ICONV_VERSION})
set(ICONV_SHA $ENV{ICONV_SHA})

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

# Configure flags for Android build
set(configure_flags
        --host=${AUTOCONF_TARGET}
        --enable-shared)


set(CONFIGURE_COMMAND
        cd "<SOURCE_DIR>" &&
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} bash "<SOURCE_DIR>/configure" ${configure_flags}
        "--prefix=${INSTALL_DIR}")
set(BUILD_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make "-j${NPROC}" -sC "<SOURCE_DIR>" install)
set(INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env ${ENV_SCRIPT_CMD} make "-j${NPROC}" -sC "<SOURCE_DIR>" install)

add_external_project(
        PROJECT_NAME libiconv
        SOURCE_DIR "${ICONV_SOURCE_DIR}"
        VERSION "${ICONV_VERSION}"
        URL "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz"
        SHA256 "${ICONV_SHA}"
        INSTALL_DIR "${INSTALL_DIR}"
        CONFIGURE_COMMAND "${CONFIGURE_COMMAND}"
        BUILD_COMMAND "${BUILD_COMMAND}"
        INSTALL_COMMAND "${INSTALL_COMMAND}"
        BUILD_BYPRODUCTS
        "${INSTALL_DIR}/lib/libiconv.so"
)

file(MAKE_DIRECTORY ${INSTALL_DIR}/include)
#file(MAKE_DIRECTORY ${INSTALL_DIR}/lib)
# Set the variables
set(ICONV_INCLUDE_DIR "${INSTALL_DIR}/include")
set(ICONV_LIBRARY ${INSTALL_DIR}/lib/libiconv.so)
set(LIB_ICONV ${INSTALL_DIR}/lib/libiconv.so)


add_library(iconv UNKNOWN IMPORTED)
add_dependencies(iconv libiconv)
set_target_properties(iconv PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "C"
        INTERFACE_INCLUDE_DIRECTORIES "${ICONV_INCLUDE_DIR}"
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/libiconv.so")


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Iconv
        REQUIRED_VARS ICONV_INCLUDE_DIR ICONV_LIBRARY
)
# Export variables for find_package compatibility
set(Iconv_INCLUDE_DIRS ${ICONV_INCLUDE_DIR})
set(Iconv_LIBRARIES ${ICONV_LIBRARY})
set(Iconv_FOUND ${ICONV_FOUND})




function(handle_dependency_trigger VAR ACCESS VALUE CURRENT_FILE STACK)
    if(ACCESS STREQUAL "READ_ACCESS")
        force_global_dependency(libiconv)
    endif()
endfunction()

variable_watch(Iconv_INCLUDE_DIRS handle_dependency_trigger)
variable_watch(Iconv_LIBRARIES handle_dependency_trigger)
variable_watch(Iconv_FOUND handle_dependency_trigger)
variable_watch(ICONV_INCLUDE_DIR handle_dependency_trigger)
variable_watch(ICONV_LIBRARY handle_dependency_trigger)
variable_watch(LIB_ICONV handle_dependency_trigger)

