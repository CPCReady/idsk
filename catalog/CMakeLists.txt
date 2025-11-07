cmake_minimum_required(VERSION 3.10)
project(catalog)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(catalog
    catalog.cpp
    dsk.cpp
)

# Installation
install(TARGETS catalog DESTINATION bin)
