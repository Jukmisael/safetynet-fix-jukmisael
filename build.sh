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

cd "$tmp_dir" || exit

pushd "$src_dir/riru" || exit
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd || exit

pushd "$src_dir/java_riru" || exit
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
ls
popd || exit

pushd "$src_dir/zygisk" || exit
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd || exit

pushd "$src_dir/java_zygisk" || exit
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd || exit

unzip "$src_dir/riru/out/safetynet-fix-"*.zip
unzip "$src_dir/zygisk/out/"*zip

version="$(grep '^version=' module.prop  | cut -d= -f2)"

rm -f "$src_dir/safetynet-fix-v"*.zip

unzip "$src_dir/java_riru/app/build/outputs/apk/release/app-release.apk" classes.dex

unzip "$src_dir/java_zygisk/app/build/outputs/apk/release/app-release.apk" -d "$src_dir/java_zygisk/app/build/outputs/apk/release/app-release.apk/tmp/classes.dex"
mv "$src_dir/java_zygisk/app/build/outputs/apk/release/app-release.apk/tmp/classes.dex" zygisk_classes.dex

sha256sum classes.dex | cut -d' ' -f1 | tr -d '\n' > classes.dex.sha256sum
sha256sum zygisk_classes.dex | cut -d' ' -f1 | tr -d '\n' > zygisk_classes.dex.sha256sum

zip -r9 "$src_dir/safetynet-fix-$version.zip" .
