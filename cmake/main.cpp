#include <iostream>
#include "hello.h"

int main(){
	std::cout << "main" << std::endl;
	std::cout << hello("world") << std::endl;
	return 0;
}