# traced: 4.14 커널에 AF_VSOCK 없음 -> relay 포트 prop 제거 (traced 크래시 루프 해결)
SET_PROP "product" "traced.relay_producer_port" --delete

# qchdcpkprov: 대상 HW에 없는 HDCP 키 프로비저닝, 반복 실패
DELETE_FROM_WORK_DIR "system" "system/bin/qchdcpkprov"

# RAM Plus: 6GB 기기에서도 8/12GB 옵션 노출 (getAvailSizeList의 RAM 값을 8로 고정)
DECODE_APK "system" "system/framework/services.jar"
NS="$(find "$APKTOOL_DIR/system/framework/services.jar" -name NandswapManager.smali | head -1)"
[ -f "$NS" ] || ABORT "NandswapManager.smali not found"
if ! grep -q "a82xq-ramplus" "$NS"; then
    LOG "- Patching RAM Plus size list (2,4,6,8,12)"
    sed -i '/^\.method public static getAvailSizeList()/,/^\.end method/ s/^    long-to-int v2, v4$/    long-to-int v2, v4\n\n    const\/16 v2, 0x8 # a82xq-ramplus/' "$NS"
    grep -q "a82xq-ramplus" "$NS" || ABORT "RAM Plus patch did not apply"
fi
