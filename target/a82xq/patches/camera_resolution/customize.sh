# The S24U SamsungCamera Resolution enum has no 4624x3468-family sizes used by the a82xq HAL
# (getResolution -> -1 crash, live focus HAL crash with 4000x3000). Add them.
DECODE_APK "system" "system/priv-app/SamsungCamera/SamsungCamera.apk"
LOG "- Adding a82xq sensor sizes to SamsungCamera Resolution enum"
python3 "$MODPATH/cam_res_patch.py" "$APKTOOL_DIR/system/priv-app/SamsungCamera/SamsungCamera.apk" \
    || ABORT "cam_res_patch.py failed"
