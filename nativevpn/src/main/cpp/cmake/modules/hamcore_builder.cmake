function(build_hamcore_se2  SOFTETHER_SOURCE_DIR  DESTINATION_DIR)
    # Set up paths
    set(TOP_DIRECTORY "${SOFTETHER_SOURCE_DIR}")
    set(BUILD_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/hamcore")
    file(MAKE_DIRECTORY "${BUILD_DIRECTORY}")

    # Generate versioned filename
    string(REPLACE "." "_" SOFTETHERVPN_VERSION_CLEAN "${SOFTETHERVPN_VERSION}")
    set(HAMCORE_SE2_FILENAME "hamcore_se2_${SOFTETHERVPN_VERSION_CLEAN}")

    # Create temporary CMakeLists.txt with absolute paths
    set(TEMP_CMAKE_FILE "${BUILD_DIRECTORY}/CMakeLists.txt")
    file(WRITE "${TEMP_CMAKE_FILE}" "
cmake_minimum_required(VERSION 3.10)
project(hamcore_builder_host)

list(APPEND CMAKE_MODULE_PATH \"${CMAKE_SOURCE_DIR}/cmake/modules\")

find_package(ZLIB REQUIRED)

set(TOP_DIRECTORY \"${TOP_DIRECTORY}\")

# libhamcore (absolute path)
add_subdirectory(\${TOP_DIRECTORY}/src/libhamcore libhamcore)
add_dependencies(libhamcore ZLIB::ZLIB)

# hamcorebuilder utility (absolute path)
add_subdirectory(\${TOP_DIRECTORY}/src/hamcorebuilder hamcorebuilder)

if(WIN32)
    set(ZLIB_DLL_TO_COPY \"$<IF:$<CONFIG:Debug>,zlibd1.dll,zlib1.dll>\")
    add_custom_target(copy_zlib_dll_\${OUTPUT_CONFIG}
            COMMAND  \${CMAKE_COMMAND} -E make_directory  \"\$<TARGET_FILE_DIR:hamcorebuilder>\"
            COMMAND \${CMAKE_COMMAND} -E copy_if_different
                \"\${INSTALL_DIR}/bin/\${ZLIB_DLL_TO_COPY}\"
                \"\$<TARGET_FILE_DIR:hamcorebuilder>\"
            COMMENT \"Copying \${ZLIB_DLL_TO_COPY} to output directory for \${CMAKE_CURRENT_BINARY_DIR}/\$<CONFIG>\"
            VERBATIM
    )
    add_dependencies(copy_zlib_dll_\${OUTPUT_CONFIG} ZLIB::ZLIB)
endif()

# hamcore.se2 archive file
add_custom_target(hamcore-archive-build ALL
    DEPENDS \"${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}\"
)
add_dependencies(hamcore-archive-build copy_zlib_dll_\${OUTPUT_CONFIG} hamcorebuilder)
add_custom_command(
    OUTPUT \"${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}\"
    COMMAND hamcorebuilder
            \"${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}\"
            \"\${TOP_DIRECTORY}/src/bin/hamcore\"
    DEPENDS hamcorebuilder
            \"\${TOP_DIRECTORY}/src/bin/hamcore/\"
    WORKING_DIRECTORY \"\${CMAKE_CURRENT_BINARY_DIR}\"
    COMMENT \"Building ${HAMCORE_SE2_FILENAME} archive file...\"
    VERBATIM
)
")

    # Custom command to configure the hamcore builder project by the host toolchain
    add_custom_command(
        OUTPUT "${BUILD_DIRECTORY}/CMakeCache.txt"
        COMMAND ${CMAKE_COMMAND} -S "${BUILD_DIRECTORY}" -B "${BUILD_DIRECTORY}"
        DEPENDS "${TEMP_CMAKE_FILE}"
        WORKING_DIRECTORY "${BUILD_DIRECTORY}"
        COMMENT "Configuring hamcore builder project"
    )

    # Custom command to build the hamcore builder
    add_custom_command(
        OUTPUT "${BUILD_DIRECTORY}/${HAMCORE_SE2_FILENAME}"
        COMMAND ${CMAKE_COMMAND} --build "${BUILD_DIRECTORY}" --config ${CMAKE_BUILD_TYPE}
        DEPENDS "${BUILD_DIRECTORY}/CMakeCache.txt"
                "${TOP_DIRECTORY}/src/bin/hamcore"
                ${ZLIB_LIBRARY}
        WORKING_DIRECTORY "${BUILD_DIRECTORY}"
        COMMENT "Building hamcorebuilder and hamcore.se2 archive"
    )

    # Main target that depends on the archive
    add_custom_target(hamcore-archive ALL
        DEPENDS "${BUILD_DIRECTORY}/${HAMCORE_SE2_FILENAME}"
    )
endfunction()
