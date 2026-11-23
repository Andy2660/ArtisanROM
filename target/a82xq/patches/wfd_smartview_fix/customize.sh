# Smart View / wireless display black screen (I-08)
# The S928N 64-bit ACodec sends the legacy 32-bit vendor OMX encoder a 24-byte
# VideoNativeMetadata, but the encoder only allocates 12 bytes, so every frame
# is rejected ("goes beyond the capacity", "clear inputbuffer").
# Port of the MinsOS/GoRhanHee I-08 fix, re-derived for S928NKSS6DZH2:
#  A: allocateBuffersOnPort, metadata type 0x65 buffer size 12 -> 24
#  B: onInputBufferFilled 0xc9ec0, replace the "Can't marshall" error branch with
#     MediaCodecBuffer::base -> GraphicBuffer::from -> OMXBuffer(sp<GraphicBuffer>)
#     -> IOMXNode::emptyBuffer, then rejoin the normal path at 0xc9e6c
SF="$WORK_DIR/system/system/lib64/libstagefright.so"
[ -f "$SF" ] || ABORT "wfd: lib64/libstagefright.so missing"

A_OLD="1f95017161030054970180521a000014"
A_NEW="1f95017161030054170380521a000014"
B_OLD="800240f9ec858e9249fdffb029853d91aafcffb04a012891010040f91f9501714901899a1f9901712b001ccb6b010c8b6a1dcb936bfcffd06be515917501899a5f0900f1a2230054c21c0694e40300aae1fcffd021a43c9102fdffd042381b91a0008052e30315aa05088052891c0694"
B_NEW="1f95017161030054800240f989220694000440f9e82300917a220694e0630091e12300917d220694e00740f9600000b4e1230091eb1c0694690e40f9369940f9c80240f9085140f9e00316aaa1435fb8e2630091e31340b9a4835cf8851e40b900013fd6d2ffff171f2003d51f2003d5"

HEX="$(xxd -p -c 0 "$SF")"
CNT() { { grep -o "$1" <<< "$HEX" || true; } | wc -l; }

if [ "$(CNT "$A_NEW")" = "1" ] && [ "$(CNT "$B_NEW")" = "1" ]; then
    LOG "- lib64/libstagefright.so already carries the I-08 fix"
    unset SF A_OLD A_NEW B_OLD B_NEW HEX; unset -f CNT; return 0
fi
[ "$(CNT "$A_OLD")" = "1" ] || ABORT "wfd: part A anchor not found exactly once - libstagefright changed, re-derive"
[ "$(CNT "$B_OLD")" = "1" ] || ABORT "wfd: part B anchor not found exactly once - libstagefright changed, re-derive"

LOG "- Patching lib64/libstagefright.so (I-08 Smart View metadata marshalling)"
HEX_PATCH "$SF" "$A_OLD" "$A_NEW"
HEX_PATCH "$SF" "$B_OLD" "$B_NEW"

HEX="$(xxd -p -c 0 "$SF")"
[ "$(CNT "$A_NEW")" = "1" ] && [ "$(CNT "$B_NEW")" = "1" ] && [ "$(CNT "$B_OLD")" = "0" ] \
    || ABORT "wfd: I-08 patch did not land cleanly"
unset SF A_OLD A_NEW B_OLD B_NEW HEX; unset -f CNT
