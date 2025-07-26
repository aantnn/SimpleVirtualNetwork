# Clone and open in Android Studio on Linux 
# Dependencies
For Linux/Unix host
```
Perl modules: FindBin, IPC::Cmd, File::Compare, File::Copy 
GNU make, sed, bash, minimal standart linux tools (for ./configure)
```
For Windows host
```
Cygwin Perl and Perl modules: FindBin, IPC::Cmd, File::Compare, File::Copy 
    - forward slash issues with Openssl's Perl /Configure)
Msys GNU make, sed, bash, etc (for bash ./configure)
    - Cygwin does not work armv7a-linux-androideabi{VER}-clang 
    - path like /cygwindrive/c/.. produce not found errors
```

# OR Install SDK
```bash
# Dependencies for OpenSSL: perl-FindBin, perl-core, perl-lib
# Android Studio initiates a configuration step upon opening a project.
# These dependencies are required during this configuration step for OpenSSL header generation. 
# Without them, the configuration step will fail.
# See: https://github.com/bugzhunter1/SimpleVirtualNetwork/blob/070c6c84c585c441702b019bc3dc535604e71d60/nativevpn/src/main/cpp/cmake/modules/FindOpenSSL.cmake#L88
apt-get update && apt-get install -y \
    wget unzip openjdk-17-jdk python3 git perl \
    build-essential pkg-config;

export NDK_VERSION="28.0.13004108"
export CMAKE_VERSION="3.31.6"
export ANDROID_VERSION="36"
export BUILD_TOOLS="36.0.0"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"
export MIN_SDK_VERSION=24

mkdir -p ${ANDROID_HOME} && \
    cd ${ANDROID_HOME} && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip commandlinetools-linux*.zip && \
    rm commandlinetools-linux*.zip && \
    cd cmdline-tools/bin && \
    yes | ./sdkmanager --sdk_root=${ANDROID_HOME} --install \
        "platform-tools" \
        "platforms;android-${ANDROID_VERSION}" \
        "ndk;${NDK_VERSION}" \
        "build-tools;${BUILD_TOOLS}" \
        "cmake;${CMAKE_VERSION}"
```
# Build deps of sofrethervpn and build libvpnclient.so
```bash
set -Eeuo pipefail
set -o nounset
set -o errexit
export NDK_VERSION="28.0.13004108"
export CMAKE_VERSION="3.31.6"
export ANDROID_VERSION="36"
export BUILD_TOOLS="36.0.0"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"
export MIN_SDK_VERSION=24

cd SimpleVirtualNetwork
 while IFS='=' read -r key value; do
    [[ $key =~ ^#.*$ || -z $key ]] && continue;     
    key=$(echo $key | xargs);     value=$(echo $value | xargs);     
    export "$key"="$value"; done < ./nativevpn/deps.txt 
cd nativevpn/src/main/cpp/

CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"


ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
for ANDROID_ABI in "${ABIS[@]}"; do
    echo "Configuring for ABI: ${ANDROID_ABI}"
    mkdir -p "build_${ANDROID_ABI}"
    (cd "build_${ANDROID_ABI}"
        ${CMAKE_BIN} \
            -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=${ANDROID_ABI} \
            -DANDROID_PLATFORM=android-${MIN_SDK_VERSION} \
            ..
        ${CMAKE_BIN} --build . -j$(nproc)
    )
done
```

# Note: Files to look at
[SoftetherVPN patch](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/softethervpn.patch) 

