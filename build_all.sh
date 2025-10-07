#!/usr/bin/env bash
set -e

# =====================================================
#   iDSK - Multi-platform Build Script (macOS host)
#   Builds for: macOS (ARM/Intel), Linux (x86_64/ARM64)
# =====================================================

PROJECT_NAME="iDSK"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
TOOLCHAIN_DIR="$ROOT_DIR/toolchains"
CORES=$(sysctl -n hw.ncpu)

# ANSI color helpers
msg() { echo -e "\n\033[1;32m👉 $1\033[0m"; }
warn() { echo -e "\033[1;33m⚠️  $1\033[0m"; }
error() { echo -e "\033[1;31m❌ $1\033[0m"; exit 1; }

# Check if a binary toolchain exists
check_toolchain() { [[ -x "$1" ]]; }

# Build a specific target
build_target() {
    local TARGET=$1
    local EXTRA_ARGS=$2
    local OUT_DIR="$BUILD_DIR/$TARGET"

    msg "🔨 Compilando para $TARGET..."
    mkdir -p "$OUT_DIR"
    cmake -S "$ROOT_DIR" -B "$OUT_DIR" -DCMAKE_BUILD_TYPE=Release $EXTRA_ARGS
    cmake --build "$OUT_DIR" -j"$CORES"

    local BIN="$OUT_DIR/$PROJECT_NAME"
    if [[ -f "$BIN" ]]; then
        file "$BIN"
        package_target "$TARGET" "$BIN"
    else
        warn "No se generó el binario esperado en $OUT_DIR"
    fi
}

# Package the resulting binary into dist/
package_target() {
    local TARGET=$1
    local BIN_PATH=$2
    mkdir -p "$DIST_DIR/$TARGET"
    cp "$BIN_PATH" "$DIST_DIR/$TARGET/"
    pushd "$DIST_DIR" >/dev/null
    tar -czf "${PROJECT_NAME}_${TARGET}.tar.gz" "$TARGET"
    popd >/dev/null
    msg "📦 Paquete generado: dist/${PROJECT_NAME}_${TARGET}.tar.gz"
}

# Clean build directories
clean_build() {
    msg "🧹 Limpiando directorios temporales..."
    rm -rf "$BUILD_DIR"
    msg "✅ Limpieza completa"
}

# Handle script arguments
MODE=${1:-all}

if [[ "$MODE" == "clean" ]]; then
    clean_build
    rm -rf "$DIST_DIR"
    msg "🧽 Limpieza total (build + dist)"
    exit 0
fi

# ===============================
# macOS builds
# ===============================
if [[ "$MODE" == "all" || "$MODE" == "macos" ]]; then
    msg "🍎 Compilando para macOS ARM64 (nativo)..."
    build_target "macos-arm" ""

    msg "🍏 Compilando para macOS Intel (x86_64)..."
    build_target "macos-x86" "-DCMAKE_OSX_ARCHITECTURES=x86_64"
fi

# ===============================
# Linux builds
# ===============================
if [[ "$MODE" == "all" || "$MODE" == "linux" ]]; then

    if check_toolchain "/opt/homebrew/opt/x86_64-unknown-linux-gnu/bin/x86_64-unknown-linux-gnu-g++"; then
        msg "🐧 Compilando para Linux x86_64..."
        build_target "linux-x86" "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_DIR/linux-x86_64.cmake"
    else
        warn "Toolchain Linux x86_64 no encontrado."
        echo "    Instálalo con:"
        echo "    brew tap messense/macos-cross-toolchains"
        echo "    brew install x86_64-unknown-linux-gnu"
    fi

    if check_toolchain "/opt/homebrew/opt/aarch64-unknown-linux-gnu/bin/aarch64-unknown-linux-gnu-g++"; then
        msg "🐧 Compilando para Linux ARM64 (Raspberry Pi)..."
        build_target "linux-arm64" "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_DIR/linux-arm64.cmake"
    else
        warn "Toolchain Linux ARM64 no encontrado."
        echo "    brew install aarch64-unknown-linux-gnu"
    fi
fi

# ===============================
# Summary
# ===============================
msg "✅ Compilación completa. Paquetes generados en:"
ls -lh "$DIST_DIR"/*.tar.gz 2>/dev/null || warn "No se generaron paquetes."

# ===============================
# Auto clean
# ===============================
clean_build
msg "🧹 Limpieza automática finalizada."