cmake_minimum_required(VERSION 3.16)
project(mbgl-renderer VERSION 0.9.0)

# Set package info for CPack
set(CPACK_PACKAGE_NAME "mbgl-renderer")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Static Map Renderer using MapLibre GL")
set(CPACK_PACKAGE_DESCRIPTION "Create static map images using MapLibre GL with a command-line interface, an HTTP interface, and a NodeJS API.")
set(CPACK_PACKAGE_VENDOR "Conservation Biology Institute")
set(CPACK_PACKAGE_CONTACT "info@consbio.org")

# Detect target architecture for Debian packaging
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
    set(DEB_ARCH "arm64")
else()
    set(DEB_ARCH "amd64")
endif()

# Debian-specific settings
set(CPACK_DEBIAN_PACKAGE_DEPENDS "nodejs (>= 18), npm, libopengl0, libuv1, xvfb")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "${DEB_ARCH}")
set(CPACK_DEBIAN_PACKAGE_SECTION "utils")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

# Set release number from environment if available (for CI builds)
if(DEFINED ENV{BUILDKITE_BUILD_NUMBER})
    set(CPACK_DEBIAN_PACKAGE_RELEASE $ENV{BUILDKITE_BUILD_NUMBER})
else()
    set(CPACK_DEBIAN_PACKAGE_RELEASE "1")
endif()

# Find required programs
find_program(NODE_EXECUTABLE NAMES node nodejs REQUIRED)
find_program(NPM_EXECUTABLE NAMES npm REQUIRED)

# Define installation directories
set(NODE_MODULE_DIR "/usr/lib/node_modules/mbgl-renderer")
set(BIN_DIR "/usr/bin")

# Custom target to install dependencies and build
add_custom_target(build_app ALL
    COMMENT "Building mbgl-renderer Node.js application"
)

# Install all dependencies for build (including dev dependencies for Babel)
add_custom_command(TARGET build_app PRE_BUILD
    COMMAND ${NPM_EXECUTABLE} ci
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Installing npm dependencies"
)

# Build with Babel
add_custom_command(TARGET build_app PRE_BUILD
    COMMAND ${NPM_EXECUTABLE} run build
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building with Babel"
    DEPENDS ${CMAKE_SOURCE_DIR}/src
)

# Install the built application
install(DIRECTORY ${CMAKE_SOURCE_DIR}/dist/
    DESTINATION ${NODE_MODULE_DIR}/dist/
    FILES_MATCHING PATTERN "*.js"
)

# Install node_modules (production dependencies only)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/node_modules/
    DESTINATION ${NODE_MODULE_DIR}/node_modules/
    PATTERN "test*" EXCLUDE
    PATTERN "*.md" EXCLUDE
    PATTERN "*.txt" EXCLUDE
    PATTERN "example*" EXCLUDE
    PATTERN "benchmark*" EXCLUDE
)

# Install package.json
install(FILES ${CMAKE_SOURCE_DIR}/package.json
    DESTINATION ${NODE_MODULE_DIR}/
)

# Create binary wrappers
file(WRITE ${CMAKE_BINARY_DIR}/mbgl-render
"#!/bin/bash
exec ${NODE_EXECUTABLE} ${NODE_MODULE_DIR}/dist/cli.js \"$@\"
")

file(WRITE ${CMAKE_BINARY_DIR}/mbgl-server
"#!/bin/bash
exec ${NODE_EXECUTABLE} ${NODE_MODULE_DIR}/dist/server.js \"$@\"
")

# Install binary wrappers
install(PROGRAMS
    ${CMAKE_BINARY_DIR}/mbgl-render
    ${CMAKE_BINARY_DIR}/mbgl-server
    DESTINATION ${BIN_DIR}
)

# Install documentation
install(FILES
    ${CMAKE_SOURCE_DIR}/README.md
    ${CMAKE_SOURCE_DIR}/LICENSE
    ${CMAKE_SOURCE_DIR}/CHANGES.md
    DESTINATION /usr/share/doc/mbgl-renderer/
)

# Enable CPack
include(CPack)