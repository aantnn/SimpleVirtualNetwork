# FindMSYS.cmake
# This module finds the MSYS installation directory and appends it to the system PATH
#
# The module defines the following variables:
#  MSYS_FOUND        - True if MSYS was found
#  MSYS_EXECUTABLE   - Path to the MSYS bash executable
#  MSYS_INSTALL_DIR  - Path to the MSYS installation directory
#  MSYS_BIN_DIR      - Path to the MSYS bin directory

# Initialize search paths list
set(MSYS_SEARCH_PATHS)

# Iterate over all possible drive letters (A-Z)
foreach(DRIVE_LETTER RANGE 65 90)
    # Convert ASCII code to character
    string(ASCII ${DRIVE_LETTER} DRIVE)

    # Add standard MSYS paths for this drive
    list(APPEND MSYS_SEARCH_PATHS
            "${DRIVE}:/msys64/usr/bin"
            "${DRIVE}:/msys64/usr/bin"
    )
endforeach()

# Add environment variable locations
list(APPEND MSYS_SEARCH_PATHS
        "$ENV{ProgramFiles}/msys64/usr/bin"
        "$ENV{ProgramFiles}/msys64/usr/bin"
        "$ENV{ProgramW6432}/msys64/usr/bin"
        "$ENV{ProgramW6432}/msys64/usr/bin"
        "$ENV{MSYS_ROOT}/usr/bin"
        "$ENV{MSYS_HOME}/usr/bin"
)

# Look for MSYS bash executable
find_program(MSYS_EXECUTABLE
        NAMES bash.exe
        PATHS ${MSYS_SEARCH_PATHS}
        DOC "Path to MSYS bash executable"
)

# If found, determine the installation directory
if(MSYS_EXECUTABLE)
    get_filename_component(MSYS_BIN_DIR "${MSYS_EXECUTABLE}" DIRECTORY)
    get_filename_component(MSYS_INSTALL_DIR "${MSYS_BIN_DIR}" DIRECTORY)
    set(CURRENT_PATH "$ENV{PATH}")
    # Check if the MSYS bin directory is already in the PATH
    if(NOT "${CURRENT_PATH}" MATCHES "${MSYS_BIN_DIR}")
        # Append the MSYS bin directory to the PATH
        set(ENV{PATH} "${MSYS_BIN_DIR};${CURRENT_PATH}")
        #message(STATUS "Added ${MSYS_BIN_DIR} to system PATH")
    endif()
endif()

set(MSYS_FOUND TRUE)

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Msys
        REQUIRED_VARS MSYS_EXECUTABLE MSYS_INSTALL_DIR MSYS_BIN_DIR
)

mark_as_advanced(MSYS_EXECUTABLE)
