#!/bin/bash
set -eux

# Install build dependencies
apt-get update -q

apt-get install -qy \
    cmake \
    nodejs \
    pkg-config \
    libgles2-mesa-dev \
    curl

rm -rf build

CMAKE_OVERRIDES=
if [ -n "${BUILDKITE_BUILD_NUMBER}" ]; then
    CMAKE_OVERRIDES="-DCPACK_DEBIAN_PACKAGE_RELEASE=${BUILDKITE_BUILD_NUMBER}"
fi
# CMake build and package

cmake -DLINUX=1 -B build -S . ${CMAKE_OVERRIDES}
cmake --build build
pushd build
cpack -G DEB
popd

