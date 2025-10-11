#!/bin/bash


# Script para compilar iDSK para múltiples plataformas y crear bottles
# Created by Destroyer 2025

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="idsk"
VERSION="${1:-}"

show_help() {
    echo "Uso: $0 <version>"
    echo "Ejemplo: $0 0.20"
    echo ""
    echo "Este script:"
    echo "1. Compila para múltiples plataformas usando CMake"
    echo "2. Crea bottles de Homebrew"
    echo "3. Calcula SHA256 de todos los artefactos"
}

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Debes especificar una versión${NC}"
    show_help
    exit 1
fi

echo -e "${GREEN}🔨 Compilando $PROJECT_NAME v$VERSION para múltiples plataformas${NC}"

# Función para actualizar la versión en Main.h
update_version_in_source() {
    local new_version=$1
    echo -e "${BLUE}🔄 Actualizando versión en src/Main.h a $new_version...${NC}"
    
    # Crear backup del archivo original
    cp src/Main.h src/Main.h.backup
    
    # Actualizar la línea #define VERSION
    sed -i.tmp "s/#define VERSION \".*\"/#define VERSION \"$new_version-CPCReady\"/" src/Main.h
    rm -f src/Main.h.tmp
    
    # Verificar que el cambio se hizo correctamente
    if grep -q "#define VERSION \"$new_version-CPCReady\"" src/Main.h; then
        echo -e "${GREEN}✅ Versión actualizada correctamente en src/Main.h${NC}"
    else
        echo -e "${RED}❌ Error: No se pudo actualizar la versión en src/Main.h${NC}"
        # Restaurar backup
        mv src/Main.h.backup src/Main.h
        exit 1
    fi
    
    # Eliminar backup si todo salió bien
    rm -f src/Main.h.backup
}

# Limpiar builds anteriores
echo -e "${BLUE}🧹 Limpiando builds anteriores...${NC}"
rm -rf build/ bottles/ artifacts/ *.tar.gz
mkdir -p build bottles artifacts

# Actualizar versión en el código fuente
update_version_in_source "$VERSION"

# Función para compilar para una plataforma específica
build_platform() {
    local platform=$1
    local cmake_args=$2
    local output_name=$3
    
    echo -e "${BLUE}🔨 Compilando para $platform...${NC}"
    
    # Crear directorio de build específico para la plataforma
    local build_dir="build/$platform"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Configurar con CMake
    if cmake -S . -B "$build_dir" -DCMAKE_BUILD_TYPE=Release $cmake_args; then
        echo -e "${GREEN}✅ Configuración CMake exitosa para $platform${NC}"
    else
        echo -e "${RED}❌ Error: No se pudo configurar CMake para $platform${NC}"
        return 1
    fi
    
    # Compilar
    if cmake --build "$build_dir" --config Release; then
        echo -e "${GREEN}✅ Compilación exitosa para $platform${NC}"
    else
        echo -e "${RED}❌ Error: No se pudo compilar para $platform${NC}"
        return 1
    fi
    
    # Verificar que el binario se creó
    local binary_path="$build_dir/$PROJECT_NAME"
    if [ ! -f "$binary_path" ]; then
        echo -e "${RED}❌ Error: No se encontró el binario $PROJECT_NAME después de compilar${NC}"
        return 1
    fi
    
    # Crear estructura para el tar
    mkdir -p "build/package_$platform"
    cp "$binary_path" "build/package_$platform/"
    
    # Crear tar.gz
    cd "build/package_$platform"
    tar -czf "../../artifacts/$output_name" "$PROJECT_NAME"
    cd ../..
    
    # Calcular SHA256
    local sha256=$(shasum -a 256 "artifacts/$output_name" | cut -d' ' -f1)
    echo -e "${GREEN}✅ $platform compilado: $output_name${NC}"
    echo -e "${GREEN}🔑 SHA256: $sha256${NC}"
    
    # Guardar SHA256 para después
    echo "$platform:$sha256:artifacts/$output_name" >> build/artifacts.txt
    
    return 0
}

# Función para crear bottle de Homebrew
create_bottle() {
    local platform=$1
    local original_file=$2
    local bottle_platform=$3
    
    echo -e "${BLUE}🍺 Creando bottle para $platform ($bottle_platform)...${NC}"
    
    # Crear estructura de bottle correcta para Homebrew
    local temp_dir="bottles/temp_$platform"
    local cellar_path="$temp_dir/opt/homebrew/Cellar/idsk/$VERSION"
    
    mkdir -p "$cellar_path/bin"
    
    # Extraer binario original
    cd "$temp_dir"
    tar -xzf "../../$original_file"
    mv "$PROJECT_NAME" "opt/homebrew/Cellar/idsk/$VERSION/bin/"
    chmod +x "opt/homebrew/Cellar/idsk/$VERSION/bin/$PROJECT_NAME"
    
    # Crear bottle con la estructura correcta
    local bottle_name="$PROJECT_NAME-$VERSION.$bottle_platform.bottle.tar.gz"
    tar -czf "../$bottle_name" opt/
    cd ../..
    
    # Calcular SHA256 del bottle
    local bottle_sha256=$(shasum -a 256 "bottles/$bottle_name" | cut -d' ' -f1)
    echo -e "${GREEN}✅ Bottle creado: $bottle_name${NC}"
    echo -e "${GREEN}🔑 Bottle SHA256: $bottle_sha256${NC}"
    
    # Guardar info del bottle
    echo "$bottle_platform:$bottle_sha256:bottles/$bottle_name" >> build/bottles.txt
    
    # Limpiar
    rm -rf "bottles/temp_$platform"
    
    return 0
}

echo -e "${BLUE}📦 Iniciando compilación multi-plataforma...${NC}"

# Detectar plataforma actual
OS_TYPE=$(uname -s)
ARCH=$(uname -m)

echo -e "${BLUE}ℹ️  Plataforma actual: $OS_TYPE $ARCH${NC}"

# macOS - Compilar para ambas arquitecturas
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo -e "${BLUE}🍎 Compilando para ambas arquitecturas de macOS...${NC}"
    
    # macOS ARM64 (Apple Silicon)
    echo -e "${BLUE}🔨 Compilando para macOS ARM64 (Apple Silicon)...${NC}"
    if [[ "$ARCH" == "arm64" ]]; then
        # Compilación nativa en Apple Silicon
        if build_platform "macos-arm64" "-DCMAKE_OSX_ARCHITECTURES=arm64" "${PROJECT_NAME}_macos-arm.tar.gz"; then
            create_bottle "macos-arm64" "artifacts/${PROJECT_NAME}_macos-arm.tar.gz" "arm64_sequoia"
            create_bottle "macos-arm64" "artifacts/${PROJECT_NAME}_macos-arm.tar.gz" "arm64_sonoma"
        fi
    else
        # Cross-compilation desde Intel a ARM64
        if build_platform "macos-arm64" "-DCMAKE_OSX_ARCHITECTURES=arm64" "${PROJECT_NAME}_macos-arm.tar.gz"; then
            create_bottle "macos-arm64" "artifacts/${PROJECT_NAME}_macos-arm.tar.gz" "arm64_sequoia"
            create_bottle "macos-arm64" "artifacts/${PROJECT_NAME}_macos-arm.tar.gz" "arm64_sonoma"
        fi
    fi
    
    # macOS x86_64 (Intel)
    echo -e "${BLUE}🔨 Compilando para macOS x86_64 (Intel)...${NC}"
    if [[ "$ARCH" == "x86_64" ]]; then
        # Compilación nativa en Intel
        if build_platform "macos-x86_64" "-DCMAKE_OSX_ARCHITECTURES=x86_64" "${PROJECT_NAME}_macos-x86.tar.gz"; then
            create_bottle "macos-x86_64" "artifacts/${PROJECT_NAME}_macos-x86.tar.gz" "sequoia"
            create_bottle "macos-x86_64" "artifacts/${PROJECT_NAME}_macos-x86.tar.gz" "sonoma"
        fi
    else
        # Cross-compilation desde ARM64 a x86_64
        if build_platform "macos-x86_64" "-DCMAKE_OSX_ARCHITECTURES=x86_64" "${PROJECT_NAME}_macos-x86.tar.gz"; then
            create_bottle "macos-x86_64" "artifacts/${PROJECT_NAME}_macos-x86.tar.gz" "sequoia"
            create_bottle "macos-x86_64" "artifacts/${PROJECT_NAME}_macos-x86.tar.gz" "sonoma"
        fi
    fi
fi

# Linux nativo (si estamos en Linux)
if [[ "$OS_TYPE" == "Linux" ]]; then
    echo -e "${BLUE}🐧 Compilando para Linux nativo...${NC}"
    if [[ "$ARCH" == "aarch64" ]]; then
        # Linux ARM64
        if build_platform "linux-arm64" "" "${PROJECT_NAME}_linux-arm64.tar.gz"; then
            create_bottle "linux-arm64" "artifacts/${PROJECT_NAME}_linux-arm64.tar.gz" "aarch64_linux"
        fi
    else
        # Linux x86_64
        if build_platform "linux-x86_64" "" "${PROJECT_NAME}_linux-x86.tar.gz"; then
            create_bottle "linux-x86_64" "artifacts/${PROJECT_NAME}_linux-x86.tar.gz" "x86_64_linux"
        fi
    fi
fi

# Compilación con Docker (si está disponible)
if command -v docker &> /dev/null; then
    echo -e "${BLUE}🐳 Docker detectado, compilando plataformas adicionales...${NC}"
    
    # Linux x86_64 con Docker (si no se compiló nativamente)
    if [[ "$OS_TYPE" != "Linux" || "$ARCH" == "aarch64" ]]; then
        echo -e "${BLUE}🐳 Compilando Linux x86_64 con Docker...${NC}"
        docker run --rm -v "$(pwd):/src" -w /src gcc:latest bash -c "
            apt-get update -qq && apt-get install -y cmake make > /dev/null 2>&1
            mkdir -p build/linux-x86_64-docker
            cmake -S . -B build/linux-x86_64-docker -DCMAKE_BUILD_TYPE=Release
            cmake --build build/linux-x86_64-docker --config Release
            mkdir -p build/package_linux-x86_64-docker
            cp build/linux-x86_64-docker/$PROJECT_NAME build/package_linux-x86_64-docker/
            cd build/package_linux-x86_64-docker
            tar -czf ../../artifacts/${PROJECT_NAME}_linux-x86.tar.gz $PROJECT_NAME
        " 2>/dev/null

        if [ -f "artifacts/${PROJECT_NAME}_linux-x86.tar.gz" ]; then
            sha256=$(shasum -a 256 "artifacts/${PROJECT_NAME}_linux-x86.tar.gz" | cut -d' ' -f1)
            echo -e "${GREEN}✅ Linux x86_64 (Docker) compilado${NC}"
            echo -e "${GREEN}🔑 SHA256: $sha256${NC}"
            echo "linux-x86_64-docker:$sha256:artifacts/${PROJECT_NAME}_linux-x86.tar.gz" >> build/artifacts.txt
            create_bottle "linux-x86_64-docker" "artifacts/${PROJECT_NAME}_linux-x86.tar.gz" "x86_64_linux"
        fi
    fi
    
    # Linux ARM64 con Docker (si no se compiló nativamente)
    if [[ "$OS_TYPE" != "Linux" || "$ARCH" != "aarch64" ]]; then
        echo -e "${BLUE}🐳 Compilando Linux ARM64 con Docker...${NC}"
        docker run --rm --platform linux/arm64 -v "$(pwd):/src" -w /src gcc:latest bash -c "
            apt-get update -qq && apt-get install -y cmake make > /dev/null 2>&1
            mkdir -p build/linux-arm64-docker
            cmake -S . -B build/linux-arm64-docker -DCMAKE_BUILD_TYPE=Release
            cmake --build build/linux-arm64-docker --config Release
            mkdir -p build/package_linux-arm64-docker
            cp build/linux-arm64-docker/$PROJECT_NAME build/package_linux-arm64-docker/
            cd build/package_linux-arm64-docker
            tar -czf ../../artifacts/${PROJECT_NAME}_linux-arm64.tar.gz $PROJECT_NAME
        " 2>/dev/null

        if [ -f "artifacts/${PROJECT_NAME}_linux-arm64.tar.gz" ]; then
            sha256=$(shasum -a 256 "artifacts/${PROJECT_NAME}_linux-arm64.tar.gz" | cut -d' ' -f1)
            echo -e "${GREEN}✅ Linux ARM64 (Docker) compilado${NC}"
            echo -e "${GREEN}🔑 SHA256: $sha256${NC}"
            echo "linux-arm64-docker:$sha256:artifacts/${PROJECT_NAME}_linux-arm64.tar.gz" >> build/artifacts.txt
            create_bottle "linux-arm64-docker" "artifacts/${PROJECT_NAME}_linux-arm64.tar.gz" "aarch64_linux"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Docker no disponible, omitiendo cross-compilation${NC}"
fi

# Generar resumen
echo ""
echo -e "${GREEN}🎉 Compilación completada!${NC}"
echo ""
echo -e "${BLUE}📋 Artefactos generados:${NC}"
if [ -f "build/artifacts.txt" ]; then
    while IFS=':' read -r platform sha256 file; do
        echo -e "  ${GREEN}✅${NC} $platform: $(basename "$file")"
        echo -e "      SHA256: $sha256"
    done < build/artifacts.txt
fi

echo ""
echo -e "${BLUE}🍺 Bottles de Homebrew generados:${NC}"
if [ -f "build/bottles.txt" ]; then
    while IFS=':' read -r platform sha256 file; do
        echo -e "  ${GREEN}✅${NC} $platform: $(basename "$file")"
        echo -e "      SHA256: $sha256"
    done < build/bottles.txt
fi

echo ""
echo -e "${BLUE}📁 Archivos creados:${NC}"
ls -la artifacts/ bottles/ 2>/dev/null || echo "No se crearon archivos"

echo ""
echo -e "${YELLOW}📝 Próximos pasos:${NC}"
echo "1. Ejecutar: ./scripts/create-release.sh $VERSION"
echo "2. Ejecutar: ./scripts/update-formula.sh $VERSION"

# Crear archivo de información para los otros scripts
cat > build/build_info.json << EOF
{
  "version": "$VERSION",
  "project_name": "$PROJECT_NAME",
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "platform": "$OS_TYPE-$ARCH",
  "artifacts_count": $([ -f "build/artifacts.txt" ] && wc -l < build/artifacts.txt || echo 0),
  "bottles_count": $([ -f "build/bottles.txt" ] && wc -l < build/bottles.txt || echo 0)
}
EOF

echo -e "${GREEN}💾 Información guardada en build/build_info.json${NC}"