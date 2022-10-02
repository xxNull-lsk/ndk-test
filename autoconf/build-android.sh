#!/bin/bash
export ANDROID_NDK_HOME=/home/allan/Android/Sdk/ndk/25.0.8775105  
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

export TARGET=aarch64-linux-android
#export TARGET=armv7a-linux-androideabi
#export TARGET=i686-linux-android
#export TARGET=x86_64-linux-android

export API=21

export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

curr=`pwd`
prefix=$curr/android/$TARGET
mkdir -p $prefix 2>/dev/null

./configure --host $TARGET --prefix=$prefix
make -j8
make install