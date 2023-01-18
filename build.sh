#!/usr/bin/env bash

tmp_dir="$(mktemp --tmpdir -d modulebuild.XXXXXXXXXX)"

cleanup() {
    rm -fr "$tmp_dir"
}
trap cleanup EXIT

build_mode="${1:-Release}"

pushd "$(dirname "$0")" || exit
src_dir="$(pwd)"
popd || exit

pushd "$src_dir/riru"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd

pushd "$src_dir/java_riru"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd

pushd "$src_dir/java_zygisk" || exit
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd || exit

unzip "$src_dir/riru/out/safetynet-fix-"*.zip

version="$(grep '^version=' module.prop  | cut -d= -f2)"

rm -f "$src_dir/safetynet-fix-v"*.zip

unzip "$src_dir/java_riru/app/build/outputs/apk/release/app-release.apk" classes.dex

unzip "$src_dir/java_zygisk/app/build/outputs/apk/release/app-release.apk" -d "$tmp_dir/java_zygisk/classes.dex"
mv "$tmp_dir/java_zygisk/classes.dex" zygisk_classes.dex

wget -P "$tmp_dir/wsfn" https://github.com/kdrag0n/safetynet-fix/releases/download/v2.4.0/safetynet-fix-v2.4.0.zip
unzip "$tmp_dir/wsfn/safetynet-fix-v2.4.0.zip" -d "$tmp_dir/sfn"
mv "$tmp_dir/sfn/zygisk" ./

sha256sum classes.dex | cut -d' ' -f1 | tr -d '\n' > classes.dex.sha256sum
sha256sum zygisk_classes.dex | cut -d' ' -f1 | tr -d '\n' > zygisk_classes.dex.sha256sum

zip -r9 "$src_dir/safetynet-fix-$version.zip" .
