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

pushd "$src_dir/riru"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd

pushd "$src_dir/java_riru"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
unzip "./app/build/outputs/apk/release/app-release.apk" classes.dex
mv classes.dex "$src_dir/classes.dex"
popd

pushd "$src_dir/java_zygisk"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
unzip "$src_dir/java_zygisk/app/build/outputs/apk/release/app-release.apk" classes.dex
mv classes.dex "$src_dir/zygisk_classes.dex
popd

pushd "$tmp_dir/"
mkdir wsfn
mkdir sfn
wget -P "./wsfn" https://github.com/kdrag0n/safetynet-fix/releases/download/v2.4.0/safetynet-fix-v2.4.0.zip
unzip "./wsfn/safetynet-fix-v2.4.0.zip" -d "./sfn"
mv "./sfn/zygisk" "$src_dir/zygisk/"
popd


unzip "$src_dir/riru/out/safetynet-fix-"*.zip

rm -f "$src_dir/safetynet-fix-v"*.zip

version="$(grep '^version=' module.prop  | cut -d= -f2)"

sha256sum classes.dex | cut -d' ' -f1 | tr -d '\n' > classes.dex.sha256sum
sha256sum zygisk_classes.dex | cut -d' ' -f1 | tr -d '\n' > zygisk_classes.dex.sha256sum

zip -r9 "$src_dir/safetynet-fix-$version.zip" .
