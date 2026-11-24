# One UI Home only offers the wireless DeX tile on phones that have a DP port
# (/sys/class/dp_sec/dex). a82xq is USB 2.0 but can do wireless DeX over Smart View.
HOME_APK="$(cd "$WORK_DIR/system/system" && find priv-app -maxdepth 2 -name '*.apk' -path '*TouchWizHome*' | head -1)"
[ -n "$HOME_APK" ] || ABORT "wireless_dex_tile: One UI Home apk not found"
DECODE_APK "system" "system/$HOME_APK"
python3 "$MODPATH/dex_tile.py" "$APKTOOL_DIR/system/$HOME_APK" || ABORT "wireless_dex_tile: patch target not found"
grep -rq "a82xq-wdex-tile" "$APKTOOL_DIR/system/$HOME_APK" || ABORT "wireless_dex_tile: marker missing"

# Settings > Connected devices > Samsung DeX is hidden (UNSUPPORTED_ON_DEVICE)
# when /sys/class/dp_sec/dex is missing. Skip that check; keep the safe-mode check.
DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
DEX_CTRL="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" -path '*com/samsung/android/settings/multidevices/dex/DexModePreferenceController.smali' | head -1)"
[ -f "$DEX_CTRL" ] || ABORT "wireless_dex_tile: DexModePreferenceController.smali not found"
sed -i '/const-string v1, "\/sys\/class\/dp_sec\/dex"/,/if-nez v0, :cond_1/ s/^    if-nez v0, :cond_1$/    goto :cond_1 # a82xq-wdex-menu/' "$DEX_CTRL"
grep -q "a82xq-wdex-menu" "$DEX_CTRL" || ABORT "wireless_dex_tile: DeX settings menu patch failed"

