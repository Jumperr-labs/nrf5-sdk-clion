#!/usr/bin/env bash
for makefile in `\find $1 -name Makefile` ; do
    \echo "Creating CMakeLists.txt for ${makefile}"
    \./nrf5-make2cmake.sh ${makefile}
done
