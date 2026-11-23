SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
    "smali_classes2/com/android/systemui/globalactions/GlobalActionsDialogLite.smali" "return" \
    'shouldDisplayLockdown(Landroid/content/pm/UserInfo;)Z' \
    'false'
