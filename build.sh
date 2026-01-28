#!/bin/bash
set -e

CORE_NAME="fceumm"
OUTPUT_DIR="dist-wasm"
RETROARCH_DIR="./retroarch-linker"
RETROARCH_REPO="${RETROARCH_REPO:-https://github.com/libretro/RetroArch.git}"
CORE_BC="${CORE_NAME}_libretro_emscripten.bc"

echo "======== 1. Ensure RetroArch linker directory exists ========"
if [ ! -d "$RETROARCH_DIR" ]; then
  echo "retroarch-linker directory missing, cloning..."
  git clone "$RETROARCH_REPO" "$RETROARCH_DIR"
fi

echo "======== 2. Clean old builds ========"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "======== 3. Build LLVM BC (core) ========"
emmake make -f Makefile.libretro platform=emscripten clean
emmake make -f Makefile.libretro platform=emscripten -j8

if [ ! -f "$CORE_BC" ]; then
  echo "ERROR: $CORE_BC not found!"
  exit 1
fi

echo "======== 4. Copy core BC into RetroArch linker ========"
cp "$CORE_BC" "$RETROARCH_DIR/libretro_emscripten.bc"

echo "======== 5. Build RetroArch WASM linker ========"
(
  cd "$RETROARCH_DIR"
  emmake make -f Makefile.emscripten LIBRETRO=${CORE_NAME} HAVE_CHEEVOS=1 HAVE_AL=0 clean
  emmake make -f Makefile.emscripten LIBRETRO=${CORE_NAME} HAVE_CHEEVOS=1 HAVE_AL=0 -j all VERBOSE=1
)

echo "======== 6. Export output ========"
cp "${RETROARCH_DIR}/${CORE_NAME}_libretro.js"   "$OUTPUT_DIR/${CORE_NAME}.js"
cp "${RETROARCH_DIR}/${CORE_NAME}_libretro.wasm" "$OUTPUT_DIR/${CORE_NAME}.wasm"

echo "======== DONE ========"
echo "Built:"
echo "  $OUTPUT_DIR/${CORE_NAME}.js"
echo "  $OUTPUT_DIR/${CORE_NAME}.wasm"
