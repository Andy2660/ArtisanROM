# Bixby 4.x 서버가 SM-A826S를 차단 (SVC_UNAVAILABLE_MODEL_NAME) -> 빅스비 앱 안에서만 모델명을 SM-S928N으로 보고
DECODE_APK "system" "system/priv-app/Bixby/Bixby.apk"
BX="$APKTOOL_DIR/system/priv-app/Bixby/Bixby.apk"
LOG "- Spoofing Build.MODEL in Bixby (SM-S928N)"
CNT=0
while IFS= read -r f; do
    sed -i -E 's/^( +)sget-object ([vp][0-9]+), Landroid\/os\/Build;->MODEL:Ljava\/lang\/String;$/\1const-string \2, "SM-S928N" # a82xq-bixby-model/' "$f"
    CNT=$((CNT+1))
done < <(grep -rlE 'Landroid/os/Build;->MODEL:Ljava/lang/String;' "$BX"/smali* | grep -vE '/(androidx|kotlin|kotlinx|com/google)/')
LOG "  patched $CNT files"
grep -rq "a82xq-bixby-model" "$BX" || ABORT "Bixby model patch did not apply"
