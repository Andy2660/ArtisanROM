KERNEL_SRC="${A82XQ_KERNEL_BOOT_IMG:-$HOME/artisan/kernel/a82xq/boot.img}"
if [ ! -f "$KERNEL_SRC" ]; then
    ABORT "kernel image not found: $KERNEL_SRC"
fi
if [ "$(stat -c %s "$KERNEL_SRC")" -gt "$TARGET_BOOT_PARTITION_SIZE" ]; then
    ABORT "kernel image is larger than the boot partition"
fi
LOG "- Using custom kernel boot.img ($(sha256sum "$KERNEL_SRC" | cut -c1-12))"
EVAL "cp -f \"$KERNEL_SRC\" \"$WORK_DIR/kernel/boot.img\""
unset KERNEL_SRC
