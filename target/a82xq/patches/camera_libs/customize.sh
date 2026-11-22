# Food mode: SecSaliencyFoodNativeNode dlopen()s these stock A826S libraries
for LIB in libFood.camera.samsung.so libFoodDetector.camera.samsung.so; do
    if [ ! -f "$WORK_DIR/system/system/lib64/$LIB" ]; then
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/$LIB" 0 0 644 "u:object_r:system_lib_file:s0"
    fi
    if ! grep -q "^$LIB$" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"; then
        LOG "- Adding $LIB to public.libraries-camera.samsung.txt"
        echo "$LIB" >> "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
    fi
done
