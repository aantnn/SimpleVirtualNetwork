include(ExternalProject)
if (TARGET iconv)
    return()
endif ()
set(ICONV_VERSION $ENV{ICONV_VERSION})
set(ICONV_SHA $ENV{ICONV_SHA})

include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)

# Configure flags for Android build
set(configure_flags
        --host=${AUTOCONF_TARGET}
        --enable-shared)


set(CONFIGURE_COMMAND
        cd "<SOURCE_DIR>" &&
        ${CMAKE_COMMAND} -E env ${android_env} "<SOURCE_DIR>/configure" ${configure_flags}
        "--prefix=<INSTALL_DIR>")
set(BUILD_COMMAND
        ${CMAKE_COMMAND} -E env ${android_env} make -j${NPROC} -sC "<SOURCE_DIR>" install)
set(INSTALL_COMMAND
        ${CMAKE_COMMAND} -E env ${android_env} make -j${NPROC} -sC "<SOURCE_DIR>" install)

#BUILD_IN_SOURCE 1 SO COPY
if (DEFINED ICONV_SOURCE_DIR AND EXISTS ${ICONV_SOURCE_DIR})
    set(COPY_SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/src/iconv")
    message(STATUS "NECESSARY Copy of sources. Reason: BUILD_IN_SOURCE 1 ExternalProject(libiconv")
    file(COPY "${ICONV_SOURCE_DIR}" DESTINATION "${COPY_SRC_DIR}/..")
    ExternalProject_Add(libiconv
            SOURCE_DIR ${COPY_SRC_DIR}
            PREFIX ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_COMMAND ""
            BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libiconv.so
    )
else ()
    ExternalProject_Add(libiconv
            URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz
            URL_HASH SHA256=${ICONV_SHA}
            PREFIX ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
            CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            BUILD_COMMAND ${BUILD_COMMAND}
            INSTALL_COMMAND ${INSTALL_COMMAND}
            DOWNLOAD_EXTRACT_TIMESTAMP 0
            BUILD_BYPRODUCTS <INSTALL_DIR>/lib/libiconv.so
    )
endif ()
ExternalProject_Get_Property(libiconv INSTALL_DIR)
ExternalProject_Get_Property(libiconv SOURCE_DIR)

file(MAKE_DIRECTORY ${INSTALL_DIR}/include)
#file(MAKE_DIRECTORY ${INSTALL_DIR}/lib)
# Set the variables
set(ICONV_INCLUDE_DIR "${SOURCE_DIR}/include;${INSTALL_DIR}/include")
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

