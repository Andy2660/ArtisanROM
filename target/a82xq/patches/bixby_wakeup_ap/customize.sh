# 하이 빅스비: 새 호출어 모델을 WCD9340 코덱 DSP가 실행 못 해 STHAL이 멈춤 -> DSP 사용 안 함 (AP 방식)
# BixbyWakeup은 버튼 호출 녹음에도 쓰이므로 앱은 유지
DECODE_APK "system" "system/app/BixbyWakeup/BixbyWakeup.apk"
python3 "$MODPATH/wakeup_ap.py" "$APKTOOL_DIR/system/app/BixbyWakeup/BixbyWakeup.apk" || ABORT "wakeup_ap.py failed"
[ "$(grep -rl "a82xq-wakeup-ap" "$APKTOOL_DIR/system/app/BixbyWakeup/BixbyWakeup.apk" | wc -l)" -ge 1 ] || ABORT "wakeup AP patch not applied"
