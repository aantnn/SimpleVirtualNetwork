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

# OpenSSL configuration
set(OPENSSL_VERSION "$ENV{OPENSSL_VERSION}" CACHE STRING "OpenSSL version")
set(OPENSSL_URL "$ENV{OPENSSL_URL}" CACHE STRING "OpenSSL URL")
set(OPENSSL_SHA "$ENV{OPENSSL_SHA}" CACHE STRING "openssl sha256sum")
set(OPENSSL_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/openssl)
download_and_extract("${OPENSSL_URL}" "${OPENSSL_SHA}" "${OPENSSL_SOURCE_DIR}")

# libsodium configuration
set(SODIUM_VERSION "$ENV{SODIUM_VERSION}" CACHE STRING "libsodium version")
set(SODIUM_URL "$ENV{SODIUM_URL}" CACHE STRING "libsodium URL")
set(SODIUM_SHA "$ENV{SODIUM_SHA}" CACHE STRING "libsodium sha256sum")
set(SODIUM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/libsodium)
download_and_extract("${SODIUM_URL}" "${SODIUM_SHA}" "${SODIUM_SOURCE_DIR}")

# libiconv configuration
set(ICONV_VERSION "$ENV{ICONV_VERSION}" CACHE STRING "libiconv version")
set(ICONV_SHA "$ENV{ICONV_SHA}" CACHE STRING "libiconv sha256")
set(ICONV_URL "$ENV{ICONV_URL}" CACHE STRING "libiconv URL")
set(ICONV_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/iconv)
download_and_extract("${ICONV_URL}" "${ICONV_SHA}" "${ICONV_SOURCE_DIR}")

# SoftEther VPN configuration
set(SOFTETHERVPN_VERSION "$ENV{SOFTETHERVPN_VERSION}" CACHE STRING "SoftetherVPN version")
set(SOFTETHERVPN_REPO "$ENV{SOFTETHERVPN_REPO}" CACHE STRING "SoftetherVPN repo")
set(SOFTETHERVPN_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn)

# Clone SoftEther VPN repository
find_package(Git REQUIRED)
clone_if_not_exists(
        "${SOFTETHERVPN_REPO}"
        "${SOFTETHERVPN_VERSION}"
        "${SOFTETHERVPN_SOURCE_DIR}"
)

# Find required packages
find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(libsodium REQUIRED)
find_package(Iconv REQUIRED)

# Build HamCore
include(${CMAKE_CURRENT_LIST_DIR}/cmake/modules/hamcore_builder.cmake)
build_hamcore_se2(
        "${SOFTETHERVPN_SOURCE_DIR}"
        "${CMAKE_SOURCE_DIR}/../res/raw"
)

# Apply SoftEther VPN patch
execute_process(
        COMMAND git apply "${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn.patch"
        WORKING_DIRECTORY "${SOFTETHERVPN_SOURCE_DIR}"
        RESULT_VARIABLE git_result
)
if(NOT git_result EQUAL "0")
        #message(FATAL_ERROR "git apply patch")
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
set(NPROC ${nproc})

# Android helpers library
add_library(androidhelpers INTERFACE)
target_include_directories(androidhelpers INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_compile_definitions(androidhelpers INTERFACE androidhelpers=1)

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


