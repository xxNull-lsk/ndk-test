对于C/C++程序员来说，通常都是针对Linux、Windows这些桌面系统的。但是，现在移动端开发非常普及。虽然安卓系统的App是用Java写的，但是，基于性能考虑，往往会把一些性能敏感的功能用C/C++实现。本文就以C/C++的视角记录了使用NDK编译各种C++工程的方法，包括cmake、autoconf、Makefile等等各种项目的编译方法。没有介绍`ndk-build`是因为这种编译方式是针对安卓设计的。本文所有方法都参考了[官方文档](https://developer.android.com/ndk/guides)。

# CMAKE项目

在cmake中提供了NDK的支持。通常只需要传递一个简单的参数就可以使用NDK编译了。完整的命令行参数为：

```bash
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-$MINSDKVERSION \
    $OTHER_ARGS
```

## CMAKE_TOOLCHAIN_FILE

【必选】cmake工具链文件的路径。其中，变量$NDK为NDK的根目录。

## ANDROID_ABI

【必选】该参数用来指定目标ABI。可以为：`armeabi-v7a`、`arm64-v8a`、`x86`、`x86_64`。

## ANDROID_ARM_MODE

【可选】指定是为 armeabi-v7a 生成 arm 还是 thumb 指令。对其他 ABI 没有影响。thumb 指令可以减少生成文件的大小。

## ANDROID_STL

【可选】指定编译时使用的stl库。取值如下：

| 值         | 说明                                                         |
| ---------- | ------------------------------------------------------------ |
| c++_shared | [libc++](https://developer.android.com/ndk/guides/cpp-support#libc) 的共享库变体。 |
| c++_static | 【默认】[libc++](https://developer.android.com/ndk/guides/cpp-support#libc) 的静态库变体。 |
| none       | 不支持 C++ 标准库。                                          |
| system     | 系统 STL。该库对STL的支持非常有限。                          |

## ANDROID_PLATFORM

指定应用或库所支持的最低 API 级别。此值对应于应用的 `minSdkVersion`。通常使用默认的即可。

## 例子

例子实现了一个安卓下运行的可执行程序，该可执行程序会加载自己编写的so库，调用其中的函数打印字符串。demo程序很简单，包含一个名hello的动态库，一个名为demo的可执行程序。逻辑非常简单，就不做过多解释了。代码如下：

- `hello.h`

```c
#ifndef HELLO_H
#define HELLO_H

void hello(const char* msg);

#endif
```

- `hello.cpp`

```c
#include <iostream>
#include "hello.h"

void hello(const char* msg){
    std::cout << "hello " << msg << std::endl;
}
```

- `main.cpp`

```c
#include <iostream>
#include "hello.h"

int main(){
	std::cout << "main" << std::endl;
    hello("world");
	return 0;
}
```

- `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.0)

project("demo")

add_library(hello SHARED hello.cpp hello.h)
add_executable(demo main.cpp hello.h)

target_link_libraries(demo hello)
```

- 编译方法

```bash
#!/bin/bash

ABI=arm64-v8a
# 该路径是我电脑上NDK的安装路径，你可以根据自己的环境更改。
NDK=/home/allan/Android/Sdk/ndk/25.0.8775105

if [ ! -e "build/android/$ABI" ]; then
    mkdir -p build/android/$ABI
fi

cd build/android/$ABI
cmake \
    -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI \
    ../../..

make -j8
```

  编译完成后，我们就可以在`build/android/arm64-v8a`目录下找到我们编译出来的`demo`和`libhello.so`了。

- 运行方法

  因为我们编译的是一个命令行程序，并非普通的安卓程序。所以，你无法直接在手机上面运行。不过，可以在AidLux里面运行。我们先把出来的`demo`和`libhello.so`放到手机存储的ndk-test目录中，然后，进入AidLux的终端执行：

```
cp /storage/emulated/0/ndk-test ~
cd ~/ndk-test
export LD_LIBRARY_PATH=.
./demo
```

<img src="https://home.mydata.top:8684/blog/20221002154025-1.jpg" style="zoom:50%;" />

# Autoconf项目

有很多开源功能是使用Autoconf构建的。比如OpenSSL、libpng、gmp等等。对于这类库有一个典型的特点就是其源码目录下会存在一个名为`Configure`或者`configure`的脚本。编译时需要先运行这个脚本生成Makefile。有些开源项目的编译脚本本身对NDK做了支持，如OpenSSL，只需按照其要求传入参数即可。还有一些没有对NDK做专门的支持，如libpng、gmp，我们就需要通过一些环境变量调整编译时所用的工具。

## OpenSSL

其源码目录的`NOTES.ANDROID`中，详细的讲解了如何编译出安卓使用的版本。关键部分摘抄如下：

```bash
export ANDROID_NDK_HOME=/home/whoever/Android/android-sdk/ndk/20.0.5594570
PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH
./Configure android-arm64 -D__ANDROID_API__=29
make
```

至于`./Configure`后面的`android-arm64`，可以是：`android-arm`、`android-arm64`、`android-armeabi`、`android-mips`、`android-mips64`、`android-x86`、`android-x86_64`、`android64`、`android64-aarch64`、`android64-mips64`、`android64-x86_64`中的任何一个。这些值可以通过`./Configure --help`查到。

不过，我通常习惯改一下prefix，这样执行`make install`时可以很方便的把编译后的东西收集起来，而不至于影响当前系统。

```bash
#!/bin/bash
export ANDROID_NDK_HOME=/home/allan/Android/Sdk/ndk/25.0.8775105  
export TARGET=android-arm64
export API=21
export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

curr=`pwd`
prefix=$curr/android/$TARGET
mkdir -p $prefix 2>/dev/null

./Configure $TARGET -D__ANDROID_API__=$API --prefix=$prefix
make -j8
make install
```

这样编译完成后就可以在`$curr/android/$TARGET`下面找到所有的文件了，包括库、头文件等等。

## libpng

在libpng、gmp这类库中，其编译脚本并没有针对Android做支持。我们可以通过下面的方法的脚本编译它。

```bash
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
```

执行完脚本后，就可以在`$curr/android/$TARGET`目录下找到所有的文件了，包括库、头文件等等。

# Makefile项目

还有一些项目是直接使用Makefile进行编译的。典型的如`libbzip2`。我们也可以通过覆盖变量的方式编译。如：

```bash
#!/bin/bash
export ANDROID_NDK_HOME=/home/allan/Android/Sdk/ndk/25.0.8775105  
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

export TARGET=aarch64-linux-android
#export TARGET=armv7a-linux-androideabi
#export TARGET=i686-linux-android
#export TARGET=x86_64-linux-android

export API=21

# Build.
make \
    CC=$TOOLCHAIN/bin/$TARGET$API-clang \
    AR=$TOOLCHAIN/bin/llvm-ar \
    RANLIB=$TOOLCHAIN/bin/llvm-ranlib \
    bzip2
```

需要注意的是，不同的项目有可能需要覆盖不同的变量。`libbzip2`只需要覆盖`CC`、`AR`和`RANLIB`这三个就可以了。如果遇到C++功能，可能还要覆盖`CXX`。

