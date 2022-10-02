#include <iostream>
#include "hello.h"

std::string xxx;

const char* hello(const char* msg){
    xxx = "hello ";
    xxx += msg;
    return xxx.c_str();
}
