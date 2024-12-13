include(ExternalProject)
if (SODIUM_FOUND OR TARGET sodium)
    return()
endif ()
set(SODIUM_SHA $ENV{SODIUM_SHA})
set(SODIUM_VERSION $ENV{SODIUM_VERSION})


include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)

set(configure_flags
        --host=${AUTOCONF_TARGET})

if (ANDROID_ABI STREQUAL "arm64-v8a")
    list(APPEND configure_command ${configure_command} CFLAGS=-march=armv8-a+crypto+aes)
endif ()


set(CONFIGURE_COMMAND
        cd "<SOURCE_DIR>" &&
        ${CMAKE_COMMAND} -E env ${android_env} "<SOURCE_DIR>/configure" ${configure_flags}
        "--prefix=<INSTALL_DIR>")
set(BUILD_COMMAND
        ${CMAKE_COMMAND} -E env ${android_env} make -j${NPROC} -sC "<SOURCE_DIR>" install)
set(INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env ${android_env} make -j${NPROC} -sC "<SOURCE_DIR>" install)


if (DEFINED SODIUM_SOURCE_DIR AND EXISTS ${SODIUM_SOURCE_DIR})
    set(COPY_SRC_DIR "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/src/libsodium/")
    message(STATUS "NECESSARY Copy of sources. Reason: BUILD_IN_SOURCE 1 ExternalProject(libsodium")
    file(COPY "${SODIUM_SOURCE_DIR}" DESTINATION "${COPY_SRC_DIR}/..")
    ExternalProject_Add(libsodium
            SOURCE_DIR ${COPY_SRC_DIR}
            PREFIX ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_COMMAND ""
            BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libsodium.so
    )
else ()
    ExternalProject_Add(libsodium
            URL https://github.com/jedisct1/libsodium/archive/refs/tags/${SODIUM_VERSION}.tar.gz
            URL_HASH SHA256=${SODIUM_SHA}
            PREFIX ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_EXTRACT_TIMESTAMP 0
            BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libsodium.so
    )
endif ()
ExternalProject_Get_Property(libsodium INSTALL_DIR)
ExternalProject_Get_Property(libsodium SOURCE_DIR)

file(MAKE_DIRECTORY ${INSTALL_DIR}/include)

#for pkg_search_module
set(SODIUM_INCLUDE_DIRS ${SOURCE_DIR}/src/libsodium/include;${INSTALL_DIR}/include)
set(SODIUM_LIBRARIES ${INSTALL_DIR}/lib/libsodium.so)
set(SODIUM_LINK_LIBRARIES ${INSTALL_DIR}/lib/libsodium.so)


add_library(sodium UNKNOWN IMPORTED)
add_dependencies(sodium libsodium)
set_target_properties(sodium PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "C"
        INTERFACE_INCLUDE_DIRECTORIES "${SOURCE_DIR}/src/libsodium/include;${INSTALL_DIR}/include"
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/libsodium.so")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Sodium
        REQUIRED_VARS SODIUM_INCLUDE_DIRS SODIUM_LIBRARIES
)





