#!/bin/bash
# Script to extract version information from an ITGMania directory
# Usage: ./extract-version.sh [--prefix PREFIX] /path/to/itgmania [simple]
# Returns: PREFIX-X.Y.Z or PREFIX-X.Y.Z-githash depending on whether a matching tag exists

set -e

# Initialize variables
PREFIX=""
SIMPLE_MODE=""
ITGMANIA_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "${1}" in
        --prefix)
            PREFIX="${2}"
            shift 2
            ;;
        --*)
            echo "Error: Unknown option ${1}" >&2
            exit 1
            ;;
        *)
            if [ -z "${ITGMANIA_DIR}" ]; then
                ITGMANIA_DIR="${1}"
            elif [ -z "${SIMPLE_MODE}" ]; then
                SIMPLE_MODE="${1}"
            else
                echo "Error: Too many arguments" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "${ITGMANIA_DIR}" ] || [ ! -d "${ITGMANIA_DIR}" ]; then
    echo "Error: Please provide a valid ITGMania directory path" >&2
    echo "Usage: ${0} [--prefix PREFIX] /path/to/itgmania [simple]" >&2
    exit 1
fi

# Extract version from SMDefs.cmake
VERSION_MAJOR=$(grep -E "^set\(SM_VERSION_MAJOR" "${ITGMANIA_DIR}/CMake/SMDefs.cmake" 2>/dev/null | sed -E 's/.*MAJOR[[:space:]]+([0-9]+).*/\1/')
VERSION_MINOR=$(grep -E "^set\(SM_VERSION_MINOR" "${ITGMANIA_DIR}/CMake/SMDefs.cmake" 2>/dev/null | sed -E 's/.*MINOR[[:space:]]+([0-9]+).*/\1/')
VERSION_PATCH=$(grep -E "^set\(SM_VERSION_PATCH" "${ITGMANIA_DIR}/CMake/SMDefs.cmake" 2>/dev/null | sed -E 's/.*PATCH[[:space:]]+([0-9]+).*/\1/')

if [ -z "${VERSION_MAJOR}" ] || [ -z "${VERSION_MINOR}" ] || [ -z "${VERSION_PATCH}" ]; then
    echo "Error: Could not extract version information from ${ITGMANIA_DIR}/CMake/SMDefs.cmake" >&2
    exit 1
fi

# Build base version string
VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"

# Initialize result
RESULT="${VERSION}"

# Add git hash if needed (not in simple mode and no matching tag)
if [ "${SIMPLE_MODE}" != "simple" ]; then
    # Get the current git hash
    cd "${ITGMANIA_DIR}"
    GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
    
    # Try fetching tags
    git fetch --tags >/dev/null 2>&1 || true
    
    # Check if there's a tag matching the version
    if ! git tag -l | grep -q "^v${VERSION}$"; then
        # No version tag, include hash
        RESULT="${VERSION}-${GIT_HASH}"
    fi
fi

# Add prefix if provided and output final result
if [ -n "${PREFIX}" ]; then
    echo "${PREFIX}${RESULT}"
else
    echo "${RESULT}"
fi
