cmake_minimum_required(VERSION 3.22.1)

project("nativevpn")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")
include(${CMAKE_CURRENT_LIST_DIR}/cmake/modules/download.cmake)

# Read dependencies from deps.txt
file(READ ${CMAKE_SOURCE_DIR}/../../../../deps.txt DEPS_CONTENT)
string(REGEX REPLACE "#[^\n]*\n" "" DEPS_CONTENT "${DEPS_CONTENT}")
string(REGEX REPLACE "\n+" ";" DEPS_LINES "${DEPS_CONTENT}")
foreach(LINE ${DEPS_LINES})
        if(LINE)
                string(REGEX REPLACE "([^=]+)=(.+)" "\\1;\\2" PARTS "${LINE}")
                list(GET PARTS 0 VAR_NAME)
                list(GET PARTS 1 VAR_VALUE)
                string(STRIP "${VAR_NAME}" VAR_NAME)
                string(STRIP "${VAR_VALUE}" VAR_VALUE)
                set(${VAR_NAME} "${VAR_VALUE}" CACHE STRING "${VAR_NAME} from deps.txt")
                set(ENV{${VAR_NAME}} "${VAR_VALUE}")
        endif()
endforeach()

if(CMAKE_HOST_WIN32)
        message(STATUS "Use Cygwin Perl variant (forward slash issues in perl and OpenSSL Configure)") #--prefix=/cygwin/c...
        find_package(Cygwin REQUIRED)
        find_program(PERL_EXECUTABLE perl
                PATHS ${CYGWIN_BIN_DIR}
                NO_DEFAULT_PATH
                DOC "Perl executable in Cygwin"
        )
        find_package(Msys REQUIRED)
else()
find_package(Perl REQUIRED)
endif()
execute_process(
        COMMAND ${PERL_EXECUTABLE} -MFindBin -MIPC::Cmd -MFile::Compare -MFile::Copy -e "print \"Perl modules available\\n\""
        RESULT_VARIABLE perl_module_check
        OUTPUT_QUIET
        ERROR_QUIET
)
if(NOT perl_module_check EQUAL "0")
        message(FATAL_ERROR "Missing required Perl modules: FindBin, IPC::Cmd, File::Compare, and/or File::Copy")
endif()


# OpenSSL configuration
set(OPENSSL_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/openssl)
download_and_extract("${OPENSSL_URL}" "${OPENSSL_SHA}" "${OPENSSL_SOURCE_DIR}")

# libsodium configuration
set(SODIUM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/libsodium)
download_and_extract("${SODIUM_URL}" "${SODIUM_SHA}" "${SODIUM_SOURCE_DIR}")

# libiconv configuration
set(ICONV_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/iconv)
download_and_extract("${ICONV_URL}" "${ICONV_SHA}" "${ICONV_SOURCE_DIR}")

# SoftEther VPN configuration
set(SOFTETHERVPN_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn)

# Clone SoftEther VPN repository
find_package(Git REQUIRED)
clone_if_not_exists(
        "${SOFTETHERVPN_REPO}"
        "${SOFTETHERVPN_VERSION}"
        "${SOFTETHERVPN_SOURCE_DIR}"
)


find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
set(HAVE_EVP_PKEY_GET_RAW_PUBLIC_KEY TRUE CACHE BOOL "Override OpenSSL symbol check")
set(HAVE_SSL_CTX_SET_NUM_TICKETS TRUE CACHE BOOL "Override OpenSSL symbol check")
find_package(sodium REQUIRED)
find_package(Iconv REQUIRED)


# Apply SoftEther VPN patch
execute_process(
        COMMAND ${GIT_EXECUTABLE} apply --reverse --check "${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn.patch"
        WORKING_DIRECTORY "${SOFTETHERVPN_SOURCE_DIR}"
        RESULT_VARIABLE git_reverse_check
        OUTPUT_QUIET
        ERROR_QUIET
)
if(NOT git_reverse_check EQUAL "0")
        execute_process(
                COMMAND ${GIT_EXECUTABLE} apply "${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn.patch"
                WORKING_DIRECTORY "${SOFTETHERVPN_SOURCE_DIR}"
                RESULT_VARIABLE git_apply_result
                ERROR_VARIABLE git_error_output
        )

        if(NOT git_apply_result EQUAL "0")
                message(FATAL_ERROR "Failed to apply patch:\n${git_error_output}")
        endif()
endif()

# Curses configuration
set(CURSES_FOUND TRUE)
set(CURSES_LIBRARY " ")
set(CURSES_INCLUDE_PATH " ")

# Add SoftEther VPN modules path
list(APPEND CMAKE_MODULE_PATH "${SOFTETHERVPN_SOURCE_DIR}/src/Mayaqua/3rdparty")



# Build configuration
set(CMAKE_VERBOSE_MAKEFILE ON)
cmake_host_system_information(RESULT nproc QUERY NUMBER_OF_PHYSICAL_CORES)
set(NPROC ${nproc} CACHE INTERNAL "")

# Android helpers library
add_library(androidhelpers INTERFACE)
target_include_directories(androidhelpers INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_sources(androidhelpers INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include/androidhelpers.h"
)
# Add SoftEther VPN subdirectory
add_subdirectory("${SOFTETHERVPN_SOURCE_DIR}")

# Main library target
add_library(${CMAKE_PROJECT_NAME} SHARED
        nativevpn.c
        androidhelpers.c
)

# Link dependencies
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        android
        log
        OpenSSL::SSL
        OpenSSL::Crypto
        sodium
        iconv
        mayaqua
        cedar
        vpnclient
)
# Build Hamcore
include(${CMAKE_CURRENT_LIST_DIR}/cmake/modules/hamcore_builder.cmake)
build_hamcore_se2(
        "${SOFTETHERVPN_SOURCE_DIR}"
        "${CMAKE_SOURCE_DIR}/../res/raw"
)
add_dependencies(nativevpn hamcore-archive)