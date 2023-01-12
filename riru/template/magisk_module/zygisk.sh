#!/system/bin/sh

# Android 8.0 or newer

unzip -o "$ZIPFILE" zygisk/* post-fs-data.sh service.sh system.prop module.prop zygisk_classes.dex sepolicy.rule -d "$MODPATH" &>/dev/null

mv -f "$MODPATH/zygisk_classes.dex" "$MODPATH/classes.dex"

chmod 755 "$MODPATH/service.sh" "$MODPATH/post-fs-data.sh"