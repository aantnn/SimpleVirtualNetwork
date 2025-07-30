# - Find or build zlib compression library with robust post-find verification
#
# This module defines:
#  ZLIB_FOUND - system has zlib
#  ZLIB_INCLUDE_DIRS - the zlib include directories
#  ZLIB_LIBRARIES - link these to use zlib
#  ZLIB_VERSION - version of zlib found

include(ExternalProject)
include(FindPackageHandleStandardArgs)

if(TARGET ZLIB::ZLIB)
    return()
endif()

set(INSTALL_DIR "${CMAKE_BINARY_DIR}/prefix")

find_path(ZLIB_INCLUDE_DIR zlib.h)
if(WIN32)
    find_library(ZLIB_LIBRARY NAMES zlib zlib1)
else()
    find_library(ZLIB_LIBRARY NAMES z zlib)
endif()

if(ZLIB_LIBRARY AND ZLIB_INCLUDE_DIR)
    message(STATUS "Found system zlib: ${ZLIB_LIBRARY}")
    add_library(ZLIB::ZLIB SHARED IMPORTED)
    set_target_properties(ZLIB::ZLIB PROPERTIES
            IMPORTED_LOCATION "${ZLIB_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
    )
    mark_as_advanced(ZLIB_INCLUDE_DIR ZLIB_LIBRARY)
else()
    message(STATUS "System zlib NOT found, will build zlib locally.")
    set(ZLIB_INCLUDE_DIR "${INSTALL_DIR}/include")
    file(MAKE_DIRECTORY ${ZLIB_INCLUDE_DIR})
    if(WIN32)
        set(ZLIB_LIBRARY "${INSTALL_DIR}/lib/zlib.lib")
        set(ZLIB_DLL "${INSTALL_DIR}/bin/zlib1.dll")
    else()
        set(ZLIB_LIBRARY "${INSTALL_DIR}/lib/libz.so")
    endif()

    set(ZLIB_URL https://zlib.net/zlib-1.3.1.tar.gz)
    set(ZLIB_SHA256 9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23)

    ExternalProject_Add(
            zlib_external
            URL ${ZLIB_URL}
            URL_HASH SHA256=${ZLIB_SHA256}
            CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            -DBUILD_SHARED_LIBS=ON
            BUILD_BYPRODUCTS
            ${ZLIB_LIBRARY}
    )

    add_library(ZLIB::ZLIB SHARED IMPORTED)
    if(WIN32)
        set(ZLIB_LIBRARY_RELEASE "${INSTALL_DIR}/lib/zlib.lib")
        set(ZLIB_DLL_RELEASE "${INSTALL_DIR}/bin/zlib1.dll")
        set(ZLIB_LIBRARY_DEBUG "${INSTALL_DIR}/lib/zlibd.lib")
        set(ZLIB_DLL_DEBUG "${INSTALL_DIR}/bin/zlib1d.dll")

        set_target_properties(ZLIB::ZLIB  PROPERTIES
                IMPORTED_IMPLIB_DEBUG "${ZLIB_LIBRARY_DEBUG}"
                IMPORTED_IMPLIB_RELEASE "${ZLIB_LIBRARY_RELEASE}"
                IMPORTED_LOCATION_DEBUG "${ZLIB_DLL_DEBUG}"
                IMPORTED_LOCATION_RELEASE "${ZLIB_DLL_RELEASE}"
                INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
                IMPORTED_CONFIGURATIONS "Debug;Release")
    else()
        set_target_properties(ZLIB::ZLIB PROPERTIES
                IMPORTED_LOCATION "${ZLIB_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
                IMPORTED_CONFIGURATIONS RELEASE
                IMPORTED_LOCATION_RELEASE "${ZLIB_LIBRARY}"
        )
    endif()
    add_dependencies(ZLIB::ZLIB zlib_external)
endif()



#[[
function(get_current_stack_targets output_var)
    get_property(targets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)
    set(${output_var} ${targets} PARENT_SCOPE)
endfunction()

function(add_dependency_to_stack_targets )
    get_current_stack_targets(TARGETS)
    foreach(target ${TARGETS})
        if ("${target}" STREQUAL "zlib" OR "${target}" STREQUAL "copy-zlib")
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
variable_watch(ZLIB_INCLUDE_DIR watch_deprecated_stack_usage)
variable_watch(ZLIB_LIBRARY watch_deprecated_stack_usage)
]]