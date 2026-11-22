# Food mode: SecSaliencyFoodNativeNode dlopen()s libFoodDetector.camera.samsung.so
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libFoodDetector.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
if ! grep -q "libFoodDetector.camera.samsung.so" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"; then
    LOG "- Adding libFoodDetector.camera.samsung.so to public.libraries-camera.samsung.txt"
    echo "libFoodDetector.camera.samsung.so" >> "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
fi
