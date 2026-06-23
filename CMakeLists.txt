cmake_minimum_required(VERSION 3.10)
project(marduk_miner)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create library
add_library(marduk_miner SHARED
    miner_engine.cpp
)

# Include Android log
find_library(log-lib log)
target_link_libraries(marduk_miner ${log-lib})
