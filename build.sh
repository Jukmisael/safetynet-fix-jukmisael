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

pushd "$src_dir/java_riru"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
ls
popd

pushd "$src_dir/zygisk"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd

pushd "$src_dir/java_zygisk"
rm -fr out
chmod +x ./gradlew
./gradlew "assemble$build_mode"
popd

unzip "$src_dir/riru/out/safetynet-fix-"*.zip
unzip "$src_dir/zygisk/out/"*zip

version="$(grep '^version=' module.prop  | cut -d= -f2)"

rm -f "$src_dir/safetynet-fix-v"*.zip

unzip "$src_dir/java_riru/app/build/outputs/apk/release/app-release.apk" classes.dex

unzip "$src_dir/java_zygisk/app/build/outputs/apk/release/app-release.apk" -d "$tmp_dir/classes.dex"
mv "$tmp_dir/classex.dex" zygisk_classes.dex

sha256sum classes.dex | cut -d' ' -f1 | tr -d '\n' > classes.dex.sha256sum
sha256sum zygisk_classes.dex | cut -d' ' -f1 | tr -d '\n' > zygisk_classes.dex.sha256sum

zip -r9 "$src_dir/safetynet-fix-$version.zip" .