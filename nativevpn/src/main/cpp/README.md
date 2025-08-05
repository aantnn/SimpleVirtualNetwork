To test if compiling is working

```bash
#!/bin/bash
# Base directories
SDK_DIR="${HOME}/Android/Sdk"
PROJECT_DIR="${HOME}/AndroidStudioProjects/SimpleVirtualNetwork/nativevpn"
BUILD_DIR="${PROJECT_DIR}/.cxx/Debug/jal3n810/arm64-v8a"
OUTPUT_DIR="${PROJECT_DIR}/build/intermediates/cxx/Debug/jal3n810/obj/arm64-v8a"

# Tool paths
CMAKE="${SDK_DIR}/cmake/3.22.1/bin/cmake"
NINJA="${SDK_DIR}/cmake/3.22.1/bin/ninja"
NDK="${SDK_DIR}/ndk/28.2.13676358"

# Source directory
SRC_DIR="${PROJECT_DIR}/src/main/cpp"

# Android configuration
ANDROID_ABI="arm64-v8a"
ANDROID_PLATFORM="android-24"
ANDROID_SYSTEM_VERSION=24

OPENSSL_VERSION="3.1.4"
OPENSSL_URL="https://www.openssl.org/source/openssl-3.1.4.tar.gz"
OPENSSL_SHA="840af5366ab9b522bde525826be3ef0fb0af81c6a9ebd84caa600fea1731eee3"

SODIUM_VERSION="1.0.19"
SODIUM_URL="https://download.libsodium.org/libsodium/releases/libsodium-1.0.19-stable.tar.gz"
SODIUM_SHA="8f67bc4ed5401e8924203e3ce13f03e5a9faa591f026c41c3ed0dadc196f033e"

ICONV_VERSION="1.17"
ICONV_URL="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz"
ICONV_SHA="8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313"

SOFTETHERVPN_VERSION="5.02.5187"
SOFTETHERVPN_REPO="https://github.com/SoftEtherVPN/SoftEtherVPN.git"

cmake_config() {
    ${CMAKE} \
        -H${SRC_DIR} \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DCMAKE_SYSTEM_VERSION=${ANDROID_SYSTEM_VERSION} \
        -DANDROID_PLATFORM=${ANDROID_PLATFORM} \
        -DANDROID_ABI=${ANDROID_ABI} \
        -DCMAKE_ANDROID_ARCH_ABI=${ANDROID_ABI} \
        -DANDROID_NDK=${NDK} \
        -DCMAKE_ANDROID_NDK=${NDK} \
        -DCMAKE_TOOLCHAIN_FILE=${NDK}/build/cmake/android.toolchain.cmake \
        -DCMAKE_MAKE_PROGRAM=${NINJA} \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${OUTPUT_DIR} \
        -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${OUTPUT_DIR} \
        -DCMAKE_BUILD_TYPE=Debug \
        -B${BUILD_DIR} \
        -GNinja \
        -DOPENSSL_VERSION=${OPENSSL_VERSION} \
        -DOPENSSL_URL=${OPENSSL_URL} \
        -DOPENSSL_SHA=${OPENSSL_SHA} \
        -DSODIUM_VERSION=${SODIUM_VERSION} \
        -DSODIUM_URL=${SODIUM_URL} \
        -DSODIUM_SHA=${SODIUM_SHA} \
        -DICONV_VERSION=${ICONV_VERSION} \
        -DICONV_URL=${ICONV_URL} \
        -DICONV_SHA=${ICONV_SHA} \
        -DSOFTETHERVPN_VERSION=${SOFTETHERVPN_VERSION} \
        -DSOFTETHERVPN_REPO=${SOFTETHERVPN_REPO}
}
build_project() {
    ${NINJA} -C ${BUILD_DIR}
}

# Main execution
main() {
    echo "Configuring CMake..."
    cmake_config
    
    echo "Building project..."
    build_project
    
    echo "Build completed!"
}

main "$@"
```
