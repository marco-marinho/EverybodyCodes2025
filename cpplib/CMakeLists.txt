cmake_minimum_required(VERSION 4.1)
project(cppnif)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(cppnif SHARED src/lib.cpp)
target_include_directories(cppnif PRIVATE "/home/linuxbrew/.linuxbrew/Cellar/erlang/28.2/lib/erlang/erts-16.1.2/include/")