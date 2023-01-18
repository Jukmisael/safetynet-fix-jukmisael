#!/system/bin/sh

# Define Magisk path
MAGISKTMP="$(magisk --path)" || MAGISKTMP=/sbin
MODPATH="${0%/*}"

# Copy oem.rc file to Magisk mirror directory
[ -d "$MAGISKTMP/.magisk/mirror/early-mount/initrc.d" ] && cp -Tf "$MODPATH/oem.rc" "$MAGISKTMP/.magisk/mirror/early-mount/initrc.d/oem.rc"

# Function to check and reset property values
check_resetprop(){
    local VALUE="$(resetprop "$1")"
    [ ! -z "$VALUE" ] && [ "$VALUE" != "$2" ] && resetprop -n "$1" "$2"
}

# Function to check and reset property values if they contain a certain string
maybe_resetprop(){
    local VALUE="$(resetprop "$1")"
    [ ! -z "$VALUE" ] && echo "$VALUE" | grep -q "$2" && resetprop -n "$1" "$3"
}

# Modifying SELinux permissions
if [ "$(cat /sys/fs/selinux/enforce)" != "1" ]; then
    setenforce 1
    chmod 660 /sys/fs/selinux/enforce
    chmod 440 /sys/fs/selinux/policy
fi

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != 0 ]; do
    sleep 1
done

# Reset property values
check_resetprop ro.boot.vbmeta.device_state locked
check_resetprop ro.boot.verifiedbootstate green
check_resetprop ro.boot.flash.locked 1
check_resetprop ro.boot.veritymode enforcing
check_resetprop ro.boot.warranty_bit 0
check_resetprop ro.warranty_bit 0
check_resetprop ro.debuggable 0
check_resetprop ro.secure 1
check_resetprop ro.build.type user
check_resetprop ro.build.tags release-keys
check_resetprop ro.vendor.boot.warranty_bit 0
check_resetprop ro.vendor.warranty_bit 0
check_resetprop vendor.boot.vbmeta.device_state locked
check_resetprop vendor.boot.verifiedbootstate green
check_resetprop sys.oem_unlock_allowed 0

# Resetting prefix property values
for prefix in system vendor system_ext product oem oem vendor_dlkm odm_dlkm; do
    check_resetprop ro.${prefix}.build.type user
    check_resetprop ro.${prefix}.build.tags release-keys
done

# Deleting ro.build.selinux
selinux="$(resetprop ro.build.selinux)"
[ -z "$selinux" ] || resetprop --delete ro.build.selinux

# Function to set property value if it contains a certain string
maybe_set_prop() {
    local prop="$1"
    local contains="$2"
    local value="$3"

    if [[ "$(getprop "$prop")" == *"$contains"* ]]; then
        resetprop "$prop" "$value"
    fi
}

# Additional modifications to be done after boot is complete

# Set Magisk recovery mode
maybe_set_prop ro.bootmode recovery unknown
maybe_set_prop ro.boot.mode recovery unknown
maybe_set_prop vendor.boot.mode recovery unknown

# Set MIUI cross-region flash
maybe_set_prop ro.boot.hwc CN GLOBAL
maybe_set_prop ro.boot.hwcountry China GLOBAL

# Hide/Disable USB/ADB Debugging
setprop sys.usb.state mtp,adb
setprop sys.usb.config mtp,adb
resetprop --delete sys.usb.config
resetprop --delete sys.usb.state
resetprop -n init.svc.adbd stopped
