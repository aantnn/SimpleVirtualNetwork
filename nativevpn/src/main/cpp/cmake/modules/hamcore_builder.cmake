# hamcore_builder.cmake

string(REPLACE "." "_" SOFTETHERVPN_VERSION_CLEAN "${SOFTETHERVPN_VERSION}")
set(HAMCORE_SE2_FILENAME "hamcore_se2_${SOFTETHERVPN_VERSION_CLEAN}")

if(EXISTS "${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}")
    return()
endif()

function(build_hamcore_se2 SOFTETHER_SOURCE_DIR DESTINATION_DIR)
set(TEMP_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/hamcore_build")
set(LIBHAMCORE_BUILD_DIR "${TEMP_BUILD_DIR}/libhamcore")
set(HAMCOREBUILDER_BUILD_DIR "${TEMP_BUILD_DIR}/hamcorebuilder")

add_custom_command(
        OUTPUT "${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${TEMP_BUILD_DIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${LIBHAMCORE_BUILD_DIR}"
        COMMAND ${CMAKE_COMMAND}
        -DCMAKE_BUILD_TYPE=Release
        -S "${SOFTETHER_SOURCE_DIR}/src/libhamcore"
        -B "${LIBHAMCORE_BUILD_DIR}"
        COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY "${LIBHAMCORE_BUILD_DIR}"

        COMMAND ${CMAKE_COMMAND} -E make_directory "${HAMCOREBUILDER_BUILD_DIR}"
        COMMAND ${CMAKE_COMMAND}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_C_FLAGS=-I${SOFTETHER_SOURCE_DIR}/src/libhamcore/include/ -I${SOFTETHER_SOURCE_DIR}/3rdparty/tinydir
        -DCMAKE_EXE_LINKER_FLAGS=-L${LIBHAMCORE_BUILD_DIR} -lz
        -S "${SOFTETHER_SOURCE_DIR}/src/hamcorebuilder"
        -B "${HAMCOREBUILDER_BUILD_DIR}"
        COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY "${HAMCOREBUILDER_BUILD_DIR}"

        COMMAND ${CMAKE_COMMAND} -E make_directory "${DESTINATION_DIR}"
        COMMAND "${HAMCOREBUILDER_BUILD_DIR}/hamcorebuilder"
        "${HAMCORE_SE2_FILENAME}"
        "${SOFTETHER_SOURCE_DIR}/src/bin/hamcore"
        WORKING_DIRECTORY "${DESTINATION_DIR}"

        COMMENT "Building hamcore_se2 file"
        VERBATIM
)

add_custom_target(
        build_hamcore_se2 ALL
        DEPENDS "${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}"
)
endfunction()