#!/bin/sh
set -eu
cd /workspace
python3 bench/campfire/prepare.py
cmake -S . -B build/campfire/linux -G Ninja -DCMAKE_BUILD_TYPE=Release -DGOOSE_BUILTIN_LIBS=none -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang
cmake --build build/campfire/linux --parallel 4
export GOOSE_HOME=/workspace/bench/campfire/build/home-linux
build/campfire/linux/goose check -O2 bench/campfire/repro/http_compatibility.goose
build/campfire/linux/goose build --cc clang -o bench/campfire/build/campfire bench/campfire/campfire.goose
python3 bench/campfire/test_server.py bench/campfire/build/campfire
python3 bench/campfire/test_server.py bench/campfire/build/campfire --no-cache
build/campfire/linux/goose build --cc clang -o bench/campfire/build/cache_test bench/campfire/cache_test.goose
bench/campfire/build/cache_test
build/campfire/linux/goose build --cc clang -o bench/campfire/build/auth_test bench/campfire/auth_test.goose
bench/campfire/build/auth_test
python3 bench/campfire/repro/check.py build/campfire/linux/goose
