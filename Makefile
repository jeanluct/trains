.PHONY: all lib libtrains libtrains.a clean distclean cmake-configure

BUILD_DIR ?= build

all: cmake-configure
	+cmake --build $(BUILD_DIR)

cmake-configure:
	cmake -S . -B $(BUILD_DIR)

lib libtrains libtrains.a: cmake-configure
	+cmake --build $(BUILD_DIR) --target trains

# Clean up build artifacts but keep the CMake build tree.
clean:
	+cmake --build $(BUILD_DIR) --target clean

# Clean up everything, including build directory and generated outputs.
distclean:
	rm -rf $(BUILD_DIR) CMakeFiles CMakeCache.txt cmake_install.cmake
	rm -f src/frontend src/train lib/libtrains.a src/*.o
