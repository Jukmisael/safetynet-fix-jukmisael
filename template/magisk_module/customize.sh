#!/system/bin/sh
SKIPUNZIP=1
$BOOTMODE || abort "! Not support for installation from Recovery"

if [[ "$(getprop ro.build.version.sdk)" -lt 26 ]]; then
    ui_print ""
    ui_print "Functionality is limited on Android 7 and older."
    ui_print "Hardware-backed attestation will not be disabled."
    ui_print ""
    unzip -o "$ZIPFILE" post-fs-data.sh service.sh system.prop module.prop -d "$MODPATH" &>/dev/null
else
    zygisk_enabled="$(magisk --sqlite "SELECT value FROM settings WHERE (key='zygisk')")"
    if [ "$zygisk_enabled" == "value=1" ]; then
        ui_print "- Zygisk mode! Don't add gms to DenyList overwise module will not load"
        unzip -o "$ZIPFILE" zygisk.sh -o "$TMPDIR" &>/dev/null
        . "$TMPDIR/zygisk.sh"
    else
        ui_print "- Riru mode! MagiskHide or modded MomoHider is required!"
        unzip -o "$ZIPFILE" riru_install.sh -o "$TMPDIR" &>/dev/null
        . "$TMPDIR/riru_install.sh"
    fi
fi