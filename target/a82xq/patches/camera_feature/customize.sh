# Use stock A826S camera-feature.xml (sensor resolutions differ from the S24U source)
DELETE_FROM_WORK_DIR "system" "system/cameradata/camera-feature.xml"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/cameradata/camera-feature.xml" 0 0 644 "u:object_r:system_file:s0"

# The S24U camera app has no entries for these sizes in its Resolution table
# (getResolution -> -1 crash). Map them to sizes both the app and the HAL know.
LOG "- Remapping camera-feature.xml resolutions for the S24U camera app"
sed -i \
    -e 's/"4624x3468"/"4000x3000"/g' \
    -e 's/"4624x2604"/"3840x2160"/g' \
    -e 's/"4000x2250"/"3840x2160"/g' \
    -e 's/"4624x2084"/"4000x1800"/g' \
    -e 's/"3472x3472"/"2992x2992"/g' \
    -e 's/"2576x1160"/"2576x1932"/g' \
    "$WORK_DIR/system/system/cameradata/camera-feature.xml"
