cmake_minimum_required(VERSION 3.0)

project("demo")
set(CMAKE_CXX_STANDARD 11)

add_library(hello SHARED hello.cpp hello.h)
add_executable(demo main.cpp hello.h)

target_link_libraries(demo hello)
