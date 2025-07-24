# - Find or build zlib compression library with robust post-find verification
#
# This module defines:
#  ZLIB_FOUND - system has zlib
#  ZLIB_INCLUDE_DIRS - the zlib include directories
#  ZLIB_LIBRARIES - link these to use zlib
#  ZLIB_VERSION - version of zlib found

include(ExternalProject)
include(FindPackageHandleStandardArgs)

# First try to find system zlib
find_package(ZLIB QUIET)

if(ZLIB_FOUND)
    # Set variables to match standard FindZLIB module
    set(ZLIB_INCLUDE_DIRS ${ZLIB_INCLUDE_DIR})
    set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})

    # Try to get version if not set
    if(NOT ZLIB_VERSION)
        if(EXISTS "${ZLIB_INCLUDE_DIR}/zlib.h")
            file(READ "${ZLIB_INCLUDE_DIR}/zlib.h" ZLIB_H)
            string(REGEX MATCH "#define ZLIB_VERSION \"([^\"]+)\"" _ "${ZLIB_H}")
            set(ZLIB_VERSION "${CMAKE_MATCH_1}")
        endif()
    endif()

    # Post-find verification checks
    if(TARGET ZLIB::ZLIB)
        get_target_property(ZLIB_IMPORTED_LOCATION ZLIB::ZLIB IMPORTED_LOCATION)
        get_target_property(ZLIB_INTERFACE_INCLUDES ZLIB::ZLIB INTERFACE_INCLUDE_DIRECTORIES)

        if(NOT EXISTS "${ZLIB_IMPORTED_LOCATION}")
            message(WARNING "ZLIB imported target points to non-existent file: ${ZLIB_IMPORTED_LOCATION}")
            set(ZLIB_FOUND FALSE)
        endif()

        if(NOT EXISTS "${ZLIB_INTERFACE_INCLUDES}/zlib.h")
            message(WARNING "ZLIB include directory missing zlib.h: ${ZLIB_INTERFACE_INCLUDES}")
            set(ZLIB_FOUND FALSE)
        endif()
    else()
        # Verify library file exists
        if(NOT EXISTS "${ZLIB_LIBRARY}")
            message(WARNING "ZLIB library not found at: ${ZLIB_LIBRARY}")
            set(ZLIB_FOUND FALSE)
        endif()

        # Verify include directory has zlib.h
        if(NOT EXISTS "${ZLIB_INCLUDE_DIR}/zlib.h")
            message(WARNING "zlib.h not found in: ${ZLIB_INCLUDE_DIR}")
            set(ZLIB_FOUND FALSE)
        endif()
    endif()

    if(ZLIB_FOUND)
        find_package_handle_standard_args(zlib
                REQUIRED_VARS ZLIB_LIBRARIES ZLIB_INCLUDE_DIRS
                VERSION_VAR ZLIB_VERSION
        )
        return()
    else()
        message(STATUS "System zlib found but missing development version of it, falling back to build from source")
        unset(ZLIB_FOUND CACHE)
        unset(ZLIB_LIBRARY CACHE)
        unset(ZLIB_INCLUDE_DIR CACHE)
    endif()
endif()

# Build from source section remains the same as before
message(STATUS "zlib not found, building from source")

# Default download URL
if(NOT ZLIB_DOWNLOAD_URL)
    set(ZLIB_DOWNLOAD_URL "https://zlib.net/zlib-1.3.tar.gz")
endif()

# ... [rest of the build from source implementation remains unchanged] ...

# Additional verification for built zlib
if(EXISTS "${ZLIB_INSTALL_DIR}")
    if(NOT EXISTS "${ZLIB_INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}z${CMAKE_STATIC_LIBRARY_SUFFIX}"
            AND NOT EXISTS "${ZLIB_INSTALL_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}z${CMAKE_SHARED_LIBRARY_SUFFIX}")
        message(FATAL_ERROR "Failed to build zlib - no libraries found in ${ZLIB_INSTALL_DIR}/lib")
    endif()

    if(NOT EXISTS "${ZLIB_INSTALL_DIR}/include/zlib.h")
        message(FATAL_ERROR "Failed to build zlib - zlib.h not found in ${ZLIB_INSTALL_DIR}/include")
    endif()
endif()

find_package_handle_standard_args(zlib
        REQUIRED_VARS ZLIB_LIBRARIES ZLIB_INCLUDE_DIRS
        VERSION_VAR ZLIB_VERSION
)
