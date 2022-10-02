#!/bin/bash

if [ ! -e "build/linux" ]; then
    mkdir -p build/linux
fi

cd build/linux
cmake ../..
make -j8
