# hamcore_builder.cmake

string(REPLACE "." "_" SOFTETHERVPN_VERSION_CLEAN "${SOFTETHERVPN_VERSION}")
set(HAMCORE_SE2_FILENAME "hamcore_se2_${SOFTETHERVPN_VERSION_CLEAN}")

function(build_hamcore_se2 SOFTETHER_SOURCE_DIR DESTINATION_DIR)
    if(EXISTS "${DESTINATION_DIR}/${HAMCORE_SE2_FILENAME}")
        return()
    endif()
    set(TEMP_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/hamcore_build")
    file(MAKE_DIRECTORY "${TEMP_BUILD_DIR}")

    file(MAKE_DIRECTORY "${TEMP_BUILD_DIR}/libhamcore")
    execute_process(
        COMMAND ${CMAKE_COMMAND}
        -DCMAKE_BUILD_TYPE=Release
        "${SOFTETHER_SOURCE_DIR}/src/libhamcore"
        WORKING_DIRECTORY "${TEMP_BUILD_DIR}/libhamcore"
        RESULT_VARIABLE result
        ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Failed to configure libhamcore: ${error}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY "${TEMP_BUILD_DIR}/libhamcore"
        RESULT_VARIABLE result
        ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Failed to build libhamcore: ${error}")
    endif()


    file(MAKE_DIRECTORY "${TEMP_BUILD_DIR}/hamcorebuilder")
    set(COMP_FLAGS "-I${SOFTETHER_SOURCE_DIR}/src/libhamcore/include/ -I${SOFTETHER_SOURCE_DIR}/3rdparty/tinydir")
    set(LINK_FLAGS "-L${TEMP_BUILD_DIR}/libhamcore -lz")

    execute_process(
        COMMAND ${CMAKE_COMMAND}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_C_FLAGS=${COMP_FLAGS}
        -DCMAKE_EXE_LINKER_FLAGS=${LINK_FLAGS}
        -S "${SOFTETHER_SOURCE_DIR}/src/hamcorebuilder"
        -B "${TEMP_BUILD_DIR}/hamcorebuilder"
        RESULT_VARIABLE result
        ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Failed to configure hamcorebuilder: ${error}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY "${TEMP_BUILD_DIR}/hamcorebuilder"
        RESULT_VARIABLE result
        ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Failed to build hamcorebuilder: ${error}")
    endif()

    # Create destination directory if it doesn't exist
    file(MAKE_DIRECTORY "${DESTINATION_DIR}")

    # Run hamcorebuilder to produce versioned hamcore.se2
    execute_process(
        COMMAND "${TEMP_BUILD_DIR}/hamcorebuilder/hamcorebuilder"
        "${HAMCORE_SE2_FILENAME}"
        "${SOFTETHER_SOURCE_DIR}/src/bin/hamcore"
        WORKING_DIRECTORY "${DESTINATION_DIR}"
        RESULT_VARIABLE result
        ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Failed to generate ${HAMCORE_SE2_FILENAME}: ${error}")
    endif()

    # Clean up temporary build directory (optional)
    # file(REMOVE_RECURSE "${TEMP_BUILD_DIR}")
endfunction()
