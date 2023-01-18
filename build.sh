#!/usr/bin/env bash

build_module() {
    local name=$1
    local src_dir=$2
    local out_dir=$3
    local build_mode=${4:-Release}
    pushd "$src_dir"
    rm -fr out
    chmod +x ./gradlew
    ./gradlew "assemble$build_mode"
    unzip "app/build/outputs/apk/release/app-release.apk" classes.dex
    mv classes.dex "$out_dir/${name}_classes.dex"
    popd
}

tmp_dir="$(mktemp --tmpdir -d modulebuild.XXXXXXXXXX)"
cleanup() {
    rm -fr "$tmp_dir"
}
trap cleanup EXIT

pushd "$(dirname "$0")" || exit
src_dir="$(pwd)"
popd || exit

build_module riru "$src_dir/riru" "$tmp_dir" "$1"
build_module java_riru "$src_dir/java_riru" "$tmp_dir" "$1"
build_module java_zygisk "$src_dir/java_zygisk" "$tmp_dir" "$1"

wget -P "$tmp_dir" https://github.com/kdrag0n/safetynet-fix/releases/download/v2.4.0/safetynet-fix-v2.4.0.zip
unzip "$tmp_dir/safetynet-fix-v2.4.0.zip" -d "$tmp_dir"

version="$(grep '^version=' "$tmp_dir/module.prop"  | cut -d= -f2)"
sha256sum "$tmp_dir/classes.dex" | cut -d' ' -f1 | tr -d '\n' > "$tmp_dir/classes.dex.sha256sum"
sha256sum "$tmp_dir/zygisk_classes.dex" | cut -d' ' -f1 | tr -d '\n' > "$tmp_dir/zygisk_classes.dex.sha256sum"

zip -r9 "$src_dir/safetynet-fix-$version.zip" "$tmp_dir"/*
