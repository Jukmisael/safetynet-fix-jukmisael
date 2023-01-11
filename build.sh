#!/usr/bin/env bash

tmp_dir="$(mktemp --tmpdir -d modulebuild.XXXXXXXXXX)"

cleanup() {

    rm -fr "$tmp_dir"

}

trap cleanup EXIT

build_mode="${1:-Release}"

pushd "$(dirname "$0")"

src_dir="$(pwd)"

popd

cd "$tmp_dir"

pushd "$src_dir/riru"

rm -fr out
chmod +x ./gradlew

./gradlew "assemble$build_mode"

popd

pushd "$src_dir/java_module"

rm -fr out
chmod +x ./gradlew

./gradlew "assemble$build_mode"

popd

unzip "$src_dir/riru/out/safetynet-fix-"*.zip

unzip "$src_dir/java_module/app/build/outputs/apk/release/app-release.apk" classes.dex

sha256sum classes.dex | cut -d' ' -f1 | tr -d '\n' > classes.dex.sha256sum

rm -f "$src_dir/safetynet-fix-riru.zip"

zip -r9 "$src_dir/safetynet-fix-riru.zip" .

set -euo pipefail

build_mode="${1:-release}"

pushd "$src_dir/zygisk/module"
rm -fr libs
debug_mode=1
if [[ "$build_mode" == "release" ]]; then
    debug_mode=0
fi
git clone --recurse-submodules https://github.com/topjohnwu/Magisk.git

/usr/local/lib/android/sdk/ndk/25.1.8937393/ndk-build NDK_PROJECT_PATH="./" NDK_APPLICATION_MK="./jni/Application.mk" APP_BUILD_SCRIPT="./jni/Android.mk"

/usr/local/lib/android/sdk/ndk/25.1.8937393/ndk-build -j48 NDK_DEBUG=$debug_mode
popd

#pushd "$src_dir/java"
# Must always be release due to R8 requirement
#chmod +x ./gradlew
#popd

pushd "$src_dir"
mkdir -p "$src_dir/magisk/zygisk"
for arch in arm64-v8a armeabi-v7a x86 x86_64
do
    cp "zygisk/module/libs/$arch/libsafetynetfix.so" "magisk/zygisk/$arch.so"
done

pushd "$src_dir/magisk"
version="$(grep '^version=' module.prop  | cut -d= -f2)"
rm -f "../safetynet-fix-$version.zip" classes.dex
unzip "../java_module/app/build/outputs/apk/release/app-release.apk" "classes.dex"
zip -r9 "../safetynet-fix-zygisk.zip" .
popd