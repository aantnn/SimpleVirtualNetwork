```bash
# without container
PROJECTS_DIR="projects"
PNAME="SimpleVirtualNetwork"
MODULE_NAME="nativevpn"
WORK_DIR="$HOME/$PROJECTS_DIR/$PNAME/$MODULE_NAME/src/main/cpp/deps"


export SOFTETHERVPN_VERSION="5.02.5187"
export OPENSSL_VERSION="3.4.0"
export SODIUM_VERSION="1.0.20-RELEASE"
export ICONV_VERSION="1.17"

export BUILD_TYPE="Release"
export NDK_VERSION="28.0.13004108"
export MIN_SDK_VERSION=24
export CMAKE_VERSION="3.31.6"
export ANDROID_VERSION="36"
export BUILD_TOOLS="36.0.0"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"


CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORk_DIR/build"

```
