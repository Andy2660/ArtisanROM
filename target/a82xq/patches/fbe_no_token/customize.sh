DECODE_APK "system" "system/framework/services.jar"

F="$(find "$APKTOOL_DIR/system/framework/services.jar" -name 'StorageManagerService$StorageManagerInternalImpl.smali' | head -1)"
[ -f "$F" ] || ABORT "StorageManagerInternalImpl.smali not found"

LOG "- Forcing empty auth token in StorageManagerInternalImpl.unlockCeStorage"
perl -0pi -e 's/(\.method public final unlockCeStorage\(I\[B\[B\)V.*?)    invoke-static \{p2\}, Lcom\/android\/internal\/util\/ArrayUtils;->isEmpty\(\[B\)Z\s*move-result v1\n/$1    const\/4 v1, 0x1 # a82xq-ce-notoken\n/s' "$F"

grep -q "a82xq-ce-notoken" "$F" || ABORT "fbe_no_token patch failed"
