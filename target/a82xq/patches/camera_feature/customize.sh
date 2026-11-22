# Use stock A826S camera-feature.xml (sensor resolutions differ from the S24U source)
DELETE_FROM_WORK_DIR "system" "system/cameradata/camera-feature.xml"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/cameradata/camera-feature.xml" 0 0 644 "u:object_r:system_file:s0"
