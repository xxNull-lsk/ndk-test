本文记录了使用NDK编译各种C++工程的方法，包括cmake、autogen等等。

# CMAKE

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

```c++
#ifndef HELLO_H
#define HELLO_H

void hello(const char* msg);

#endif
```

- `hello.cpp`

```c++
#include <iostream>
#include "hello.h"

void hello(const char* msg){
    std::cout << "hello " << msg << std::endl;
}
```

- `main.cpp`

```c++
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

# Autogen

