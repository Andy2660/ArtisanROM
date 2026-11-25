SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
    "smali_classes2/com/android/systemui/globalactions/GlobalActionsDialogLite.smali" "return" \
    'shouldDisplayLockdown(Landroid/content/pm/UserInfo;)Z' \
    'false'

# Settings > 보안 잠금 상세설정 > "잠금 모드 옵션 표시" toggle (lockdown_in_power_menu).
# Samsung hides it (getAvailabilityStatus = 3 UNSUPPORTED_ON_DEVICE); the power menu's
# IS_LOCK_DOWN_IN_POWER_MENU condition already reads this setting, so only unhide it.
DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"
LD_SMALI="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" -name 'ShowLockdownModeOptionPreferenceController.smali' | head -1)"
[ -f "$LD_SMALI" ] || ABORT "ShowLockdownModeOptionPreferenceController.smali not found"
sed -i '/getAvailabilityStatus()I/,/\.end method/ s/^    const\/4 p0, 0x3$/    const\/4 p0, 0x0 # a82xq-lockdown-toggle/' "$LD_SMALI"
grep -q "a82xq-lockdown-toggle" "$LD_SMALI" || ABORT "lockdown toggle patch failed"

# Samsung hardcodes IS_LOCK_DOWN_IN_POWER_MENU to true in SystemConditionChecker.isEnabled
# (switch index 0x1c -> :pswitch_1f "const/4 p0, 0x1"), ignoring the setting.
# Make it call SettingsWrapper.isLockDownInPowerMenu() so the toggle above works.
DECODE_APK "system" "system/framework/framework.jar"
SCC_SMALI="$(find "$APKTOOL_DIR/system/framework/framework.jar" -path '*com/samsung/android/globalactions/util/SystemConditionChecker.smali' | head -1)"
[ -f "$SCC_SMALI" ] || ABORT "SystemConditionChecker.smali not found"
grep -q "a82xq-lockdown-cond" "$SCC_SMALI" || \
sed -i '/^    :pswitch_1f$/,/^    return p0$/ s/^    const\/4 p0, 0x1$/    iget-object p0, p0, Lcom\/samsung\/android\/globalactions\/util\/SystemConditionChecker;->mUtilFactory:Lcom\/samsung\/android\/globalactions\/util\/UtilFactory;\n    const-class p1, Lcom\/samsung\/android\/globalactions\/util\/SettingsWrapper;\n    invoke-interface {p0, p1}, Lcom\/samsung\/android\/globalactions\/util\/UtilFactory;->get(Ljava\/lang\/Class;)Ljava\/lang\/Object;\n    move-result-object p0\n    check-cast p0, Lcom\/samsung\/android\/globalactions\/util\/SettingsWrapper;\n    invoke-virtual {p0}, Lcom\/samsung\/android\/globalactions\/util\/SettingsWrapper;->isLockDownInPowerMenu()Z\n    move-result p0 # a82xq-lockdown-cond/' "$SCC_SMALI"
grep -q "a82xq-lockdown-cond" "$SCC_SMALI" || ABORT "lockdown condition patch failed"

# SecDisplaySettingsReceiver rewrites Settings.Secure lockdown_in_power_menu on every boot,
# undoing the user's toggle. Redirect that write to an unused key.
SDR_SMALI="$(find "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk" -name 'SecDisplaySettingsReceiver.smali' | head -1)"
[ -f "$SDR_SMALI" ] || ABORT "SecDisplaySettingsReceiver.smali not found"
sed -i 's/^    const-string p0, "lockdown_in_power_menu"$/    const-string p0, "a82xq_lockdown_boot_reset_disabled" # a82xq-lockdown-noreset/' "$SDR_SMALI"
grep -q "a82xq-lockdown-noreset" "$SDR_SMALI" || ABORT "lockdown boot reset patch failed"
