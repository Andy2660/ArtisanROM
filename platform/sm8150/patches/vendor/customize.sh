LOG_STEP_IN "- Setting Adaptive HFR flags"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms" "250"
    SET_PROP "vendor" "ro.surface_flinger.set_touch_timer_ms" "300"
    SET_PROP "vendor" "ro.surface_flinger.set_display_power_timer_ms" "200"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling Vulkan"
SET_PROP "vendor" "ro.hwui.use_vulkan" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Allowing mremap in vendor Codec2 seccomp policies"
C2_POLICY_FIRST=""
C2_POLICY_PATCHED=false
while IFS= read -r f; do
    [ -z "$C2_POLICY_FIRST" ] && C2_POLICY_FIRST="$f"
    if grep -q "^mremap:" "$f"; then
        sed -i 's/^mremap:.*/mremap: 1/' "$f"
        C2_POLICY_PATCHED=true
        LOG "- Relaxed mremap rule in $(basename "$f")"
    fi
done < <(find "$WORK_DIR/vendor/etc/seccomp_policy" -type f \( -iname "*c2*" -o -iname "*codec2*" \) 2> /dev/null)
if ! $C2_POLICY_PATCHED; then
    if [ -n "$C2_POLICY_FIRST" ]; then
        [ -n "$(tail -c1 "$C2_POLICY_FIRST")" ] && echo >> "$C2_POLICY_FIRST"
        echo "mremap: 1" >> "$C2_POLICY_FIRST"
        LOG "- Added mremap to $(basename "$C2_POLICY_FIRST")"
    else
        LOGW "No Codec2 seccomp policy found in vendor/etc/seccomp_policy"
    fi
fi
unset C2_POLICY_FIRST C2_POLICY_PATCHED
LOG_STEP_OUT

LOG_STEP_IN "- Setting ro.sf.init.lcd_density"
LCD_DENSITY="$(GET_PROP "vendor" "ro.sf.lcd_density")"
[ "$LCD_DENSITY" ] || LCD_DENSITY="$(GET_PROP "odm" "ro.sf.lcd_density")"
if [ "$(GET_PROP "vendor" "ro.sf.init.lcd_density")" ] || [ "$(GET_PROP "odm" "ro.sf.init.lcd_density")" ]; then
    LOG "- ro.sf.init.lcd_density already set, skipping"
elif [ "$LCD_DENSITY" ]; then
    SET_PROP "vendor" "ro.sf.init.lcd_density" "$LCD_DENSITY"
else
    LOGW "- ro.sf.lcd_density not found, SurfaceFlinger will fall back to 213 dpi"
fi
unset LCD_DENSITY
LOG_STEP_OUT
