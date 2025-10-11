#!/bin/bash

# Script para actualizar fórmula de Homebrew con nuevos bottles
# Created by Destroyer 2025


set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuración
PROJECT_NAME="idsk"
VERSION="${1:-}"
FORMULA_FILE="Formula/idsk.rb"
REPO="CPCReady/idsk"

show_help() {
    echo "Uso: $0 <version>"
    echo "Ejemplo: $0 0.20"
    echo ""
    echo "Este script:"
    echo "1. Lee los SHA256 de los bottles desde build/bottles.txt"
    echo "2. Calcula el SHA256 del código fuente"
    echo "3. Genera una nueva fórmula de Homebrew actualizada"
    echo "4. Valida la sintaxis de la fórmula"
}

# Validar argumentos
if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Error: Versión requerida${NC}"
    show_help
    exit 1
fi

echo -e "${BLUE}🍺 Actualizando fórmula de Homebrew para v$VERSION${NC}"

# Verificar que existe el archivo de bottles
if [ ! -f "build/bottles.txt" ]; then
    echo -e "${RED}❌ No se encontró build/bottles.txt${NC}"
    echo "Ejecuta primero: ./scripts/build-all-platforms.sh $VERSION"
    exit 1
fi

# Crear directorio Formula si no existe
if [ ! -d "Formula" ]; then
    mkdir -p Formula
    echo -e "${YELLOW}⚠️  Creado directorio Formula/${NC}"
fi

# Función para obtener SHA256 del código fuente
get_source_sha256() {
    local tarball_url="https://github.com/$REPO/archive/v$VERSION.tar.gz"
    curl -sL "$tarball_url" | shasum -a 256 | cut -d' ' -f1
}

# Obtener SHA256 del código fuente
echo -e "${BLUE}🔍 Calculando SHA256 del código fuente...${NC}"
SOURCE_SHA256=$(get_source_sha256)
echo -e "${GREEN}✅ SHA256 del código fuente: $SOURCE_SHA256${NC}"

# Leer SHA256s de los bottles
echo -e "${BLUE}📋 Leyendo SHA256s de bottles...${NC}"

# Variables para almacenar los SHA256s
ARM64_SEQUOIA_SHA=""
ARM64_SONOMA_SHA=""
SEQUOIA_SHA=""
SONOMA_SHA=""
X86_64_LINUX_SHA=""
AARCH64_LINUX_SHA=""

while IFS=':' read -r platform sha256 file; do
    case "$platform" in
        "arm64_sequoia")
            ARM64_SEQUOIA_SHA="$sha256"
            echo -e "${GREEN}  ✅ macOS ARM64 Sequoia: $sha256${NC}"
            ;;
        "arm64_sonoma")
            ARM64_SONOMA_SHA="$sha256"
            echo -e "${GREEN}  ✅ macOS ARM64 Sonoma: $sha256${NC}"
            ;;
        "sequoia")
            SEQUOIA_SHA="$sha256"
            echo -e "${GREEN}  ✅ macOS x86_64 Sequoia: $sha256${NC}"
            ;;
        "sonoma")
            SONOMA_SHA="$sha256"
            echo -e "${GREEN}  ✅ macOS x86_64 Sonoma: $sha256${NC}"
            ;;
        "x86_64_linux")
            X86_64_LINUX_SHA="$sha256"
            echo -e "${GREEN}  ✅ Linux x86_64: $sha256${NC}"
            ;;
        "aarch64_linux")
            AARCH64_LINUX_SHA="$sha256"
            echo -e "${GREEN}  ✅ Linux ARM64: $sha256${NC}"
            ;;
    esac
done < build/bottles.txt

# Verificar que tenemos al menos algunos bottles
if [ -z "$ARM64_SEQUOIA_SHA" ] && [ -z "$ARM64_SONOMA_SHA" ] && [ -z "$SEQUOIA_SHA" ] && [ -z "$SONOMA_SHA" ] && [ -z "$X86_64_LINUX_SHA" ] && [ -z "$AARCH64_LINUX_SHA" ]; then
    echo -e "${RED}❌ No se encontraron bottles en build/bottles.txt${NC}"
    exit 1
fi

# Crear la fórmula actualizada
echo -e "${BLUE}✏️  Generando fórmula actualizada...${NC}"

TAG="v$VERSION"

cat > "$FORMULA_FILE" << EOF
class Idsk < Formula
  desc "Amstrad CPC Disk Image Management Tool - Professional CLI utility for DSK files"
  homepage "https://github.com/$REPO"
  url "https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz"
  sha256 "$SOURCE_SHA256"
  license "MIT"

  # Bottles para múltiples plataformas
  bottle do
    root_url "https://github.com/$REPO/releases/download/$TAG"
EOF

# Añadir SHA256s de bottles a la fórmula
if [ -n "$ARM64_SEQUOIA_SHA" ]; then
    cat >> "$FORMULA_FILE" << EOF
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "$ARM64_SEQUOIA_SHA"
EOF
fi

if [ -n "$ARM64_SONOMA_SHA" ]; then
    cat >> "$FORMULA_FILE" << EOF
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "$ARM64_SONOMA_SHA"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "$ARM64_SONOMA_SHA"
EOF
fi

if [ -n "$SEQUOIA_SHA" ]; then
    cat >> "$FORMULA_FILE" << EOF
    sha256 cellar: :any_skip_relocation, sequoia:       "$SEQUOIA_SHA"
EOF
fi

if [ -n "$SONOMA_SHA" ]; then
    cat >> "$FORMULA_FILE" << EOF
    sha256 cellar: :any_skip_relocation, sonoma:        "$SONOMA_SHA"
    sha256 cellar: :any_skip_relocation, ventura:       "$SONOMA_SHA"
EOF
fi

if [ -n "$X86_64_LINUX_SHA" ]; then
    cat >> "$FORMULA_FILE" << EOF
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "$X86_64_LINUX_SHA"
EOF
fi

if [ -n "$AARCH64_LINUX_SHA" ]; then
    cat >> "$FORMULA_FILE" << EOF
    sha256 cellar: :any_skip_relocation, aarch64_linux: "$AARCH64_LINUX_SHA"
EOF
fi

# Continuar con el resto de la fórmula
cat >> "$FORMULA_FILE" << EOF
  end

  depends_on "cmake" => :build

  def install
    # Si estamos usando un bottle, el binario ya está en la ubicación correcta
    # Si estamos compilando desde fuente, necesitamos compilar
    if build.bottle?
      # Para bottles, simplemente copiar desde la estructura del bottle
      bin.install "bin/iDSK"
    else
      # Para compilación desde fuente
      system "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Release", *std_cmake_args
      system "cmake", "--build", "build", "--config", "Release"
      bin.install "build/iDSK"
    end
    
    # Instalar documentación si está disponible
    doc.install "README.md" if File.exist?("README.md")
    doc.install "AUTHORS" if File.exist?("AUTHORS")
    doc.install "docs/" if File.exist?("docs/BUILD.md")
  end

  test do
    # Crear un archivo DSK de prueba y verificar las funcionalidades básicas
    # Verificar que el comando existe y muestra ayuda
    output = shell_output("#{bin}/iDSK 2>&1")
    assert_match "Enhanced version", output
    assert_match "Usage", output
    assert_match "OPTIONS", output
    
    # Verificar que podemos crear un nuevo DSK
    system bin/"iDSK", "test.dsk", "-n"
    assert_path_exists testpath/"test.dsk"
  end
end
EOF

echo -e "${GREEN}✅ Fórmula actualizada en $FORMULA_FILE${NC}"

# Eliminar espacios trailing
sed -i.tmp 's/[[:space:]]*$//' "$FORMULA_FILE"
rm -f "$FORMULA_FILE.tmp"

# Validar sintaxis de la fórmula (si Ruby está disponible)
if command -v ruby &> /dev/null; then
    echo -e "${BLUE}🔍 Validando sintaxis de la fórmula...${NC}"
    if ruby -c "$FORMULA_FILE" &> /dev/null; then
        echo -e "${GREEN}✅ Sintaxis de la fórmula válida${NC}"
    else
        echo -e "${RED}❌ Error en la sintaxis de la fórmula${NC}"
        ruby -c "$FORMULA_FILE"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Ruby no encontrado, omitiendo validación de sintaxis${NC}"
fi

echo -e "${GREEN}🎉 Fórmula actualizada exitosamente${NC}"
echo -e "${BLUE}📁 Archivo: $FORMULA_FILE${NC}"
echo -e "${BLUE}🔢 Versión: $VERSION${NC}"
echo -e "${BLUE}🔑 SHA256 fuente: $SOURCE_SHA256${NC}"

echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo "1. Revisar la fórmula generada"
echo "2. Crear release: ./scripts/create-release.sh $VERSION"
echo "3. Subir fórmula al tap: git add $FORMULA_FILE && git commit -m \"Update idsk to $VERSION\""


echo ""
echo Actualizar fórmula en el repo secundario
echo -e "${BLUE}🔄 Actualizando fórmula en el repo homebrew-cpcready"
# Copiar artefactos
rsync -av Formula/ ../homebrew-cpcready/Formula/

#Commit/push en el repo secundario
echo -e "${BLUE}📤 Haciendo commit y push en homebrew-cpcready"
cd ../homebrew-cpcready/
git add .
git commit -m "update artifacts from $(date) version $VERSION"
git push origin main
cd ../$PROJECT_NAME
echo -e "${GREEN}✅ Fórmula actualizada y cambios pushados${NC}"
echo -e "${GREEN}🚀 Todo listo!${NC}"
