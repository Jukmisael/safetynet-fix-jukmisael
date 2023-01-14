#!/system/bin/sh

if [ -f "$MODDIR/debug_log.txt" ]; then
    logcat USNFbyJukmisael:* *:S >"$MODDIR/debug_log.txt" &
fi

# Function Props #
maybe_set_prop() {
    local prop="$1"
    local contains="$2"
    local value="$3"

    if [[ "$(getprop "$prop")" == *"$contains"* ]]; then
        resetprop "$prop" "$value"
    fi
}

# exec fix props #
{
	# Magisk recovery mode 
	maybe_set_prop ro.bootmode recovery unknown
	maybe_set_prop ro.boot.mode recovery unknown
	maybe_set_prop vendor.boot.mode recovery unknown

	# MIUI cross-region flash
	maybe_set_prop ro.boot.hwc CN GLOBAL
	maybe_set_prop ro.boot.hwcountry China GLOBAL

	#Hide/Disable USB/ADB Debugging
	setprop sys.usb.state mtp,adb
	setprop sys.usb.config mtp,adb

	resetprop --delete sys.usb.config
	resetprop --delete sys.usb.state
	resetprop -n init.svc.adbd stopped
	resetprop --delete init.svc.adbd

	resetprop --delete ro.build.selinux
	

	# selinux permissive #
	if [[ "$(cat /sys/fs/selinux/enforce)" == "0" ]]; then
        setenforce 1
	    chmod 640 /sys/fs/selinux/enforce
	    chmod 440 /sys/fs/selinux/policy

	fi
}

# Change Permission of addon.d #
{
	mount -o remount,rw /
	#chmod 700 /system/addon.d
	mv /system/addon.d /system/addon.dd
	chmod 700 /system/addon.dd
	mount -o remount,ro /
}

#####Try Hide init.rc modified######
{   
	MODDIR=${0%/*}
	MAGISK_TMP=$(magisk --path) || MAGISK_TMP="/sbin"
	INITRC_NAME="init.rc"
 
	# Android 11's new init.rc
	[ -f "/init.rc" ] || INITRC_NAME="system/etc/init/hw/init.rc"
 
 	INITRC="/$INITRC_NAME"
    MAGISKRC="$MAGISK_TMP/.magisk/rootdir/$INITRC_NAME"
 
    trim() {
    	trimmed=$1
        trimmed=${trimmed%% }
        trimmed=${trimmed## }
        echo $trimmed
    }
 
    # https://github.com/topjohnwu/Magisk/blob/master/native/jni/init/rootdir.cpp#L24
    grep_flash_recovery() {
       # Some devices don't have the flash_recovery service
       # (like Samsung renamed it to "ota_cleanup" but Magisk won't remove it, so we no need to do anything for this)
        LINE=$(grep "service flash_recovery " "$INITRC") || return 1
		LINE=${LINE#*"service flash_recovery "}
		trim "$LINE"
    }
 
    reset_flash_recovery() {
		FLASH_RECOVERY=$(grep_flash_recovery) || return
 
       # Skip if the flash_recovery not removed by Magisk
        grep -qxF "service flash_recovery /system/bin/xxxxx" "$MAGISKRC" || return
 
       # Skip if the install-recovery.sh not exist
        [ -f "$FLASH_RECOVERY" ] || return
 
       # Skip if there is the state set for the service
        [ "$(getprop 'init.svc.flash_recovery' 2>/dev/null)" = "" ] || return
 
       # Set a "fake" state for the service
        resetprop 'init.svc.flash_recovery' 'stopped'
    }
 
    grep_service_name() {
		ARG=$1
        LINE=$(grep "service .* $MAGISK_TMP/magisk --$ARG" "$MAGISKRC")
        LINE=${LINE#*"service "}
        LINE=${LINE%" $MAGISK_TMP"*}
        trim "$LINE"
    }
 
    del_service_name() {
		resetprop --delete "init.svc.$1"
    }
 
 }

# Late props which must be set after boot_completed #
{
    until [[ "$(getprop sys.boot_completed)" == "1" ]]; do
        sleep 1
    done

    # avoid breaking Realme fingerprint scanners
    resetprop -n ro.boot.flash.locked 1

    # avoid breaking Oppo fingerprint scanners
    resetprop -n ro.boot.vbmeta.device_state locked

    # avoid breaking OnePlus display modes/fingerprint scanners
    resetprop -n vendor.boot.verifiedbootstate green

    # Safetynet (avoid breaking OnePlus display modes/fingerprint scanners on OOS 12)
    resetprop -n ro.boot.verifiedbootstate green
    resetprop -n ro.boot.veritymode enforcing
    resetprop -n vendor.boot.vbmeta.device_state locked

    # Oneplus (avoid breaking OnePlus display modes/fingerprint scanners on OOS 12) 
    resetprop -n ro.is_ever_orange

    # make bank apps and Google Pay happy
    resetprop -n sys.oem_unlock_allowed 0

    # Google enforces hardware attestation for devices released with Android 13+
    # https://github.com/kdrag0n/safetynet-fix/issues/224
    # Simply spoof released version to lower one for now
    if [ "$(getprop ro.product.first_api_level)" -ge 33 ]; then
        resetprop -n ro.product.first_api_level 32
    fi

    # hide userdebug props #
	{
		 MAGISKDIR="$(magisk --path)"
	    [ -z "$MAGISKDIR" ] && MAGISKDIR=/sbin
	    
		for propfile in /default.prop /system/build.prop /vendor/build.prop /product/build.prop /vendor/odm/etc/build.prop; do
			cat $propfile |  grep "^ro." | grep userdebug >>"$MAGISKDIR/.magisk/hide-userdebug.prop"
			cat $propfile |  grep "^ro." | grep test-keys >>"$MAGISKDIR/.magisk/hide-userdebug.prop"
		done
		ed -i "s/userdebug/user/g" "$MAGISKDIR/.magisk/hide-userdebug.prop"
		sed -i "s/test-keys/release-keys/g" "$MAGISKDIR/.magisk/hide-userdebug.prop"
		resetprop --file "$MAGISKDIR/.magisk/hide-userdebug.prop"

	}

	delete_services() {
      # Remove Magisk's services' names from system properties
      POST_FS_DATA=$(grep_service_name "post-fs-data")
      LATE_START_SERVICE=$(grep_service_name "service")
      BOOT_COMPLETED=$(grep_service_name "boot-complete")
      del_service_name "$POST_FS_DATA"
      del_service_name "$LATE_START_SERVICE"
      del_service_name "$BOOT_COMPLETED"
    }

	reset_flash_recovery
    delete_services &
}&