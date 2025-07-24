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

# hamcorebuilder utility (absolute path)
add_subdirectory(\${TOP_DIRECTORY}/src/hamcorebuilder hamcorebuilder)

# hamcore.se2 archive file
add_custom_target(hamcore-archive-build ALL
    DEPENDS \"${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}\"
)

add_custom_command(
    OUTPUT \"${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}\"
    COMMAND \"\${CMAKE_CURRENT_BINARY_DIR}/hamcorebuilder/hamcorebuilder\"
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
                -DCMAKE_BUILD_TYPE=Release
        DEPENDS "${TEMP_CMAKE_FILE}"
        WORKING_DIRECTORY "${BUILD_DIRECTORY}"
        COMMENT "Configuring hamcore builder project"
    )

    # Custom command to build the hamcore builder
    add_custom_command(
        OUTPUT "${BUILD_DIRECTORY}/${HAMCORE_SE2_FILENAME}"
        COMMAND ${CMAKE_COMMAND} --build "${BUILD_DIRECTORY}"
        DEPENDS "${BUILD_DIRECTORY}/CMakeCache.txt"
                "${TOP_DIRECTORY}/src/bin/hamcore"
        WORKING_DIRECTORY "${BUILD_DIRECTORY}"
        COMMENT "Building hamcore.se2 archive"
    )

    # Main target that depends on the archive
    add_custom_target(hamcore-archive ALL
        DEPENDS "${BUILD_DIRECTORY}/${HAMCORE_SE2_FILENAME}"
    )
endfunction()
