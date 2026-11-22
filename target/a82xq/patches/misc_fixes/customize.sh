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

# 하이 빅스비 제거: 새 호출어 모델을 WCD9340 코덱 DSP가 실행 못 함 -> STHAL 멈춤 -> 오디오 HAL 재시작 반복/system_server 크래시
# 앱을 지워 음성 호출 메뉴 자체를 없앰 (측면 버튼 호출은 영향 없음)
DELETE_FROM_WORK_DIR "system" "system/app/BixbyWakeup"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.bixby.wakeup.xml"
