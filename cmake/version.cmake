# Define the Major, Minor, Patch and Pre-Release version components, as part of semver
set(FLAMEGPU_VERSION_MAJOR 2)
set(FLAMEGPU_VERSION_MINOR 0)
set(FLAMEGPU_VERSION_PATCH 0)
# Prerelease must be empty, alpha[.N], beta[.N] or rc[.N] for python version compatibility
set(FLAMEGPU_VERSION_PRERELEASE "alpha.1") 


# Validate the major version
if(FLAMEGPU_VERSION_MAJOR LESS 0)
    message(FATAL_ERROR "FLAMEGPU_VERSION_MAJOR (${FLAMEGPU_VERSION_MAJOR}) must be a non negative integer")
endif()
# Validate the minor version
if(FLAMEGPU_VERSION_MINOR LESS 0 OR FLAMEGPU_VERSION_MINOR GREATER 999)
    message(FATAL_ERROR "FLAMEGPU_VERSION_MINOR (${FLAMEGPU_VERSION_MINOR}) must be a non negative integer less than 1000")
endif()
# Validate the patch version
if(FLAMEGPU_VERSION_PATCH LESS 0 OR FLAMEGPU_VERSION_PATCH GREATER 999)
    message(FATAL_ERROR "FLAMEGPU_VERSION_PATCH (${FLAMEGPU_VERSION_PATCH}) must be a non negative integer less than 1000")
endif()
# Validate the prerelease version
if(NOT FLAMEGPU_VERSION_PRERELEASE STREQUAL "")
    set(FLAMEGPU_VERSION_PRERELEASE_PATTERN "^(alpha|beta|rc)(\.([0-9]+))?$")
    if(FLAMEGPU_VERSION_PRERELEASE MATCHES ${FLAMEGPU_VERSION_PRERELEASE_PATTERN})
        set(FLAMEGPU_VERSION_PRERELEASE_LABEL ${CMAKE_MATCH_1})
        set(FLAMEGPU_VERSION_PRERELEASE_NUMBER ${CMAKE_MATCH_3})
    else()
        message(FATAL_ERROR "FLAMEGPU_VERSION_PRERELEASE (${FLAMEGPU_VERSION_PRERELEASE}) must be of the pattern ${FLAMEGPU_VERSION_PRERELEASE_PATTERN}")
    endif()
    unset(FLAMEGPU_VERSION_PRERELEASE_PATTERN)
endif()

# Extract the short hash from git to use in the BUILDMETADATA component of SemVer
# Based on https://cmake.org/pipermail/cmake/2018-October/068388.html
macro(GET_COMMIT_HASH)
    # @todo - graceful error handling
    find_package(Git REQUIRED)
    if(Git_FOUND)
        set_property(
            DIRECTORY 
            APPEND 
            PROPERTY CMAKE_CONFIGURE_DEPENDS 
            "${FLAMEGPU_ROOT}/.git/index"
        )
        execute_process(
            COMMAND
                ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY
                ${FLAMEGPU_ROOT}
            RESULT_VARIABLE
                SHORT_HASH_RESULT
            OUTPUT_VARIABLE
                FLAMEGPU_SHORT_HASH
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
        set(FLAMEGPU_SHORT_HASH "") # this should never be encoutered 
    endif()
    unset(SHORT_HASH_RESULT)
endmacro()

# Get the hash from git, used as build metadata in semver.
GET_COMMIT_HASH()
set(FLAMEGPU_VERSION_BUILDMETADATA "${FLAMEGPU_SHORT_HASH}")

# Major.minor.patch version string, CMake if VERSION_ doesn't support non numeric components.
set(FLAMEGPU_VERSION "${FLAMEGPU_VERSION_MAJOR}.${FLAMEGPU_VERSION_MINOR}.${FLAMEGPU_VERSION_PATCH}")

# Major.minor.patch[-prerelease], i.e. the git tag without the preceding v 
set(FLAMEGPU_VERSION_STRING "${FLAMEGPU_VERSION}")
if(NOT ${FLAMEGPU_VERSION_PRERELEASE} STREQUAL "")
    set(FLAMEGPU_VERSION_STRING "${FLAMEGPU_VERSION_STRING}-${FLAMEGPU_VERSION_PRERELEASE}")
endif()

# Full SemVer string Major.minor.patch[-prerelease][+build] i.e. 2.0.0-alpha+abcdefg
set(FLAMEGPU_VERSION_FULL "${FLAMEGPU_VERSION_STRING}")
if(NOT ${FLAMEGPU_VERSION_BUILDMETADATA} STREQUAL "")
    set(FLAMEGPU_VERSION_FULL "${FLAMEGPU_VERSION_FULL}+${FLAMEGPU_VERSION_BUILDMETADATA}")
endif()

# Calculate the integer representation of the version to be made available as a C macro
math(EXPR FLAMEGPU_VERSION_INTEGER "(${FLAMEGPU_VERSION_MAJOR} * 1000000) + (${FLAMEGPU_VERSION_MINOR} * 1000) + ${FLAMEGPU_VERSION_PATCH}")

# Set the python version strings, as dictated by PEP 440
# Public versions must follow [N!]N(.N)*[{a|b|rc}N][.postN][.devN].
# Pre release segments must be specified as {a|b|rc}N. if N is ommitited is is implicilty 0. i.e. semver -alpha would map to a or a0
set(FLAMEGPU_VERSION_PYTHON_PUBLIC "${FLAMEGPU_VERSION}")
if(NOT FLAMEGPU_VERSION_PRERELEASE_LABEL STREQUAL "")
    set(FLAMEGPU_VERSION_PYTHON_PRERELEASE "")
    if(FLAMEGPU_VERSION_PRERELEASE_LABEL STREQUAL "alpha")
        set(FLAMEGPU_VERSION_PYTHON_PRERELEASE "a")
    elseif(FLAMEGPU_VERSION_PRERELEASE_LABEL STREQUAL "beta")
        set(FLAMEGPU_VERSION_PYTHON_PRERELEASE "b")
    elseif(FLAMEGPU_VERSION_PRERELEASE_LABEL STREQUAL "rc")
        set(FLAMEGPU_VERSION_PYTHON_PRERELEASE "rc")
    endif()
    if(NOT FLAMEGPU_VERSION_PYTHON_PRERELEASE STREQUAL "" AND NOT FLAMEGPU_VERSION_PRERELEASE_NUMBER STREQUAL "" AND FLAMEGPU_VERSION_PRERELEASE_NUMBER GREATER 0)
        set(FLAMEGPU_VERSION_PYTHON_PRERELEASE "${FLAMEGPU_VERSION_PYTHON_PRERELEASE}${FLAMEGPU_VERSION_PRERELEASE_NUMBER}")
    endif()
    set(FLAMEGPU_VERSION_PYTHON_PUBLIC "${FLAMEGPU_VERSION_PYTHON_PUBLIC}${FLAMEGPU_VERSION_PYTHON_PRERELEASE}")
    unset(FLAMEGPU_VERSION_PYTHON_PRERELEASE)
endif()

# Local python version identifiers are: <public version identifier>[+<local version label>]
# The local version number should apparently not be included in distributed versions other than downstream distributions.
set(FLAMEGPU_VERSION_PYTHON_LOCAL "${FLAMEGPU_VERSION_PYTHON_PUBLIC}")
if(NOT ${FLAMEGPU_VERSION_BUILDMETADATA} STREQUAL "")
    set(FLAMEGPU_VERSION_PYTHON_LOCAL "${FLAMEGPU_VERSION_PYTHON_LOCAL}+${FLAMEGPU_VERSION_BUILDMETADATA}")
endif()

# Unset temporary variables.
unset(FLAMEGPU_VERSION_PRERELEASE_LABEL)
unset(FLAMEGPU_VERSION_PRERELEASE_NUMBER)