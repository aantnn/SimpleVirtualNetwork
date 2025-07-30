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

#BUILD_IN_SOURCE 1 SO COPY
if (DEFINED ICONV_SOURCE_DIR AND EXISTS ${ICONV_SOURCE_DIR})
    set(COPY_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src/iconv")
    #file(COPY "${ICONV_SOURCE_DIR}" DESTINATION "${COPY_SRC_DIR}/..")
    add_custom_command(
        OUTPUT "${COPY_SRC_DIR}/Configure"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${COPY_SRC_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${ICONV_SOURCE_DIR}"
            "${COPY_SRC_DIR}"
        COMMENT "Copying libiconv sources"
        BYPRODUCTS "${COPY_SRC_DIR}"
    )
    add_custom_target(copy-libiconv DEPENDS "${COPY_SRC_DIR}/Configure")
    ExternalProject_Add(libiconv
            SOURCE_DIR ${COPY_SRC_DIR}
            #PREFIX ${INSTALL_DIR}
            DEPENDS copy-libiconv
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_COMMAND ""
            BUILD_BYPRODUCTS ${INSTALL_DIR}/lib/libiconv.so
            BUILD_IN_SOURCE 1
    )
else ()
    ExternalProject_Add(libiconv
            URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz
            URL_HASH SHA256=${ICONV_SHA}
            #PREFIX ${INSTALL_DIR}
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_EXTRACT_TIMESTAMP 0
            BUILD_BYPRODUCTS ${INSTALL_DIR}/lib/libiconv.so
            BUILD_IN_SOURCE 1
    )
endif ()
#ExternalProject_Get_Property(libiconv INSTALL_DIR)
#ExternalProject_Get_Property(libiconv SOURCE_DIR)



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


function(get_current_stack_targets output_var)
    get_property(targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
    set(${output_var} ${targets} PARENT_SCOPE)
endfunction()

function(add_dependency_to_stack_targets )
    get_current_stack_targets(TARGETS)
    foreach(target ${TARGETS})
        if ("${target}" STREQUAL "libiconv" OR "${target}" STREQUAL "copy-libiconv")
            #message(WARNING "Something wrong happened. Cannot add target openssl to openssl target\nSTACK:${stack}\n")
            continue()
        endif()
        add_dependencies(${target} libiconv)
    endforeach()
endfunction()

function(watch_deprecated_stack_usage var access value current_list_file stack)
    if(access STREQUAL "READ_ACCESS")
        add_dependency_to_stack_targets(${stack})
    endif()
endfunction()
variable_watch(Iconv_INCLUDE_DIRS watch_deprecated_stack_usage)
variable_watch(Iconv_LIBRARIES watch_deprecated_stack_usage)
variable_watch(Iconv_FOUND watch_deprecated_stack_usage)
variable_watch(ICONV_INCLUDE_DIR watch_deprecated_stack_usage)
variable_watch(ICONV_LIBRARY watch_deprecated_stack_usage)
variable_watch(LIB_ICONV watch_deprecated_stack_usage)

