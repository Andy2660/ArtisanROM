# 설정 > 배터리 정보: SM-S928N 모델에서만 사이클/성능 항목 표시 -> SM-A826S로 바꿈
DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
F="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" -name BatteryRegulatoryPreferenceController.smali | head -1)"
[ -f "$F" ] || ABORT "BatteryRegulatoryPreferenceController.smali not found"
if ! grep -q "a82xq-battinfo" "$F"; then
    LOG "- Enabling battery cycle/health info for SM-A826S"
    sed -i -E 's/^    const-string v1, "SM-[A-Z0-9]+"$/    const-string v1, "SM-A826S" # a82xq-battinfo/' "$F"
    grep -q "a82xq-battinfo" "$F" || ABORT "battery_info patch did not apply"
fi
