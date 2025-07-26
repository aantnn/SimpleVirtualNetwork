# FindCygwin.cmake
# This module finds the Cygwin installation directory and appends it to the system PATH
#
# The module defines the following variables:
#  CYGWIN_FOUND        - True if Cygwin was found
#  CYGWIN_EXECUTABLE   - Path to the Cygwin bash executable
#  CYGWIN_INSTALL_DIR  - Path to the Cygwin installation directory
#  CYGWIN_BIN_DIR      - Path to the Cygwin bin directory

# Initialize search paths list
set(CYGWIN_SEARCH_PATHS)

# Iterate over all possible drive letters (A-Z)
foreach(DRIVE_LETTER RANGE 65 90)
    # Convert ASCII code to character
    string(ASCII ${DRIVE_LETTER} DRIVE)

    # Add standard Cygwin paths for this drive
    list(APPEND CYGWIN_SEARCH_PATHS
            "${DRIVE}:/cygwin/bin"
            "${DRIVE}:/cygwin64/bin"
    )
endforeach()

# Add environment variable locations
list(APPEND CYGWIN_SEARCH_PATHS
        "$ENV{ProgramFiles}/Cygwin/bin"
        "$ENV{ProgramFiles}/Cygwin64/bin"
        "$ENV{ProgramW6432}/Cygwin/bin"
        "$ENV{ProgramW6432}/Cygwin64/bin"
        "$ENV{CYGWIN_ROOT}/bin"
        "$ENV{CYGWIN_HOME}/bin"
)

# Look for Cygwin bash executable
find_program(CYGWIN_EXECUTABLE
        NAMES bash.exe
        PATHS ${CYGWIN_SEARCH_PATHS}
        DOC "Path to Cygwin bash executable"
)

# If found, determine the installation directory
if(CYGWIN_EXECUTABLE)
    get_filename_component(CYGWIN_BIN_DIR "${CYGWIN_EXECUTABLE}" DIRECTORY)
    get_filename_component(CYGWIN_INSTALL_DIR "${CYGWIN_BIN_DIR}" DIRECTORY)
    set(CURRENT_PATH "$ENV{PATH}")
    # Check if the Cygwin bin directory is already in the PATH
    if(NOT "${CURRENT_PATH}" MATCHES "${CYGWIN_BIN_DIR}")
        # Append the Cygwin bin directory to the PATH
        set(ENV{PATH} "${CYGWIN_BIN_DIR};${CURRENT_PATH}")
        #message(STATUS "Added ${CYGWIN_BIN_DIR} to system PATH")
    endif()
endif()

set(CYGWIN_FOUND TRUE)

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Cygwin
        REQUIRED_VARS CYGWIN_EXECUTABLE CYGWIN_INSTALL_DIR CYGWIN_BIN_DIR
)

mark_as_advanced(CYGWIN_EXECUTABLE)
