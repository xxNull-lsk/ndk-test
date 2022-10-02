#!/bin/bash

ABI=arm64-v8a
NDK=/home/allan/Android/Sdk/ndk/25.0.8775105

rm -rf build/android/$ABI >/dev/null 2>&1
mkdir -p build/android/$ABI >/dev/null 2>&1

cd build/android/$ABI
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI \
    ../../..

make -j8
