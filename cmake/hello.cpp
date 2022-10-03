#include <iostream>
#include "hello.h"

const char* hello(const char* msg){
    static std::string tmp;
    tmp = "hello ";
    tmp += msg;
    return tmp.c_str();
}
