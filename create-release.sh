#!/bin/bash

# Script para crear tag y release en GitHub
# Created by Destroyer 2025


set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="iDSK"
VERSION="${1:-}"
REPO="CPCReady/idsk"

show_help() {
    echo "Uso: $0 <version>"
    echo "Ejemplo: $0 0.20"
    echo ""
    echo "Este script:"
    echo "1. Verifica que existan los artefactos compilados"
    echo "2. Crea un tag de git"
    echo "3. Crea un release en GitHub"
    echo "4. Sube todos los artefactos y bottles"
    echo ""
    echo "Prerrequisitos:"
    echo "- Ejecutar primero: ./scripts/build-all-platforms.sh <version>"
    echo "- gh CLI instalado y autenticado"
}

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Debes especificar una versión${NC}"
    show_help
    exit 1
fi

TAG="v$VERSION"

echo -e "${GREEN}🏷️ Creando release $TAG en GitHub${NC}"

# Verificar prerrequisitos
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ gh CLI no está instalado${NC}"
    echo "Instala con: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ No estás autenticado con gh CLI${NC}"
    echo "Ejecuta: gh auth login"
    exit 1
fi

# Verificar que existan los artefactos
if [ ! -d "artifacts" ] || [ ! -d "bottles" ]; then
    echo -e "${RED}❌ No se encontraron artefactos compilados${NC}"
    echo "Ejecuta primero: ./scripts/build-all-platforms.sh $VERSION"
    exit 1
fi

# Contar artefactos
ARTIFACTS_COUNT=$(find artifacts/ -name "*.tar.gz" 2>/dev/null | wc -l)
BOTTLES_COUNT=$(find bottles/ -name "*.tar.gz" 2>/dev/null | wc -l)

if [ "$ARTIFACTS_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron artefactos en artifacts/${NC}"
    echo "Ejecuta primero: ./scripts/build-all-platforms.sh $VERSION"
    exit 1
fi

echo -e "${BLUE}📦 Artefactos encontrados: $ARTIFACTS_COUNT${NC}"
echo -e "${BLUE}🍺 Bottles encontrados: $BOTTLES_COUNT${NC}"

# Verificar si el tag ya existe
if git tag | grep -q "^$TAG$"; then
    echo -e "${YELLOW}⚠️  El tag $TAG ya existe localmente${NC}"
    read -p "¿Quieres eliminarlo y recrearlo? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "$TAG"
        git push origin --delete "$TAG" 2>/dev/null || true
    else
        echo -e "${RED}❌ Cancelado${NC}"
        exit 1
    fi
fi

# Verificar si el release ya existe en GitHub
if gh release view "$TAG" --repo "$REPO" &> /dev/null; then
    echo -e "${YELLOW}⚠️  El release $TAG ya existe en GitHub${NC}"
    read -p "¿Quieres eliminarlo y recrearlo? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh release delete "$TAG" --repo "$REPO" --yes
    else
        echo -e "${RED}❌ Cancelado${NC}"
        exit 1
    fi
fi

# Crear tag local
echo -e "${BLUE}🏷️ Creando tag local $TAG...${NC}"
git tag -a "$TAG" -m "Release $TAG

iDSK - Amstrad CPC Disk Image Management Tool

Compilado para múltiples plataformas:
- macOS ARM64 (Apple Silicon)  
- macOS x86_64 (Intel)
- Linux x86_64
- Linux ARM64 (Raspberry Pi 5)

Bottles de Homebrew incluidos para instalación rápida.

Created by Destroyer 2025"

# Generar notas del release
RELEASE_NOTES="# Release $TAG

## 🚀 Novedades

Herramienta CLI profesional para gestión integral de archivos DSK (imágenes de disco Amstrad CPC).

### ✨ Características principales:
- 📁 **Gestión completa de archivos**: Importar, exportar y eliminar archivos de imágenes de disco
- 📋 **Listado de contenido**: Mostrar catálogos de disco con información detallada
- 🔍 **Análisis de archivos**: Ver programas BASIC, desensamblar código Z80, volcados hex
- 💾 **Creación de discos**: Generar nuevas imágenes DSK formateadas
- ⚙️ **Cabeceras AMSDOS**: Manejo automático de direcciones de carga/ejecución
- 🔄 **Conversión inteligente**: Conversión automática de terminaciones de línea Unix a DOS para archivos BASIC (.bas)
- 🌐 **Multi-plataforma**: Soporte nativo para x86, AMD64, ARM y Apple Silicon

## 📦 Artefactos incluidos

### Binarios por plataforma:"

# Añadir información de artefactos
if [ -f "build/artifacts.txt" ]; then
    while IFS=':' read -r platform sha256 file; do
        filename=$(basename "$file")
        RELEASE_NOTES="$RELEASE_NOTES
- **$platform**: \`$filename\` (SHA256: \`${sha256:0:16}...\`)"
    done < build/artifacts.txt
fi

RELEASE_NOTES="$RELEASE_NOTES

### Bottles de Homebrew:"

# Añadir información de bottles
if [ -f "build/bottles.txt" ]; then
    while IFS=':' read -r platform sha256 file; do
        filename=$(basename "$file")
        RELEASE_NOTES="$RELEASE_NOTES
- **$platform**: \`$filename\` (SHA256: \`${sha256:0:16}...\`)"
    done < build/bottles.txt
fi

RELEASE_NOTES="$RELEASE_NOTES

## 📥 Instalación

### Via Homebrew (Recomendado)
\`\`\`bash
brew tap CPCReady/tools
brew install idsk
\`\`\`

### Manual
1. Descarga el archivo para tu plataforma
2. Extrae: \`tar -xzf iDSK_[plataforma].tar.gz\`
3. Instala: \`sudo mv iDSK /usr/local/bin/\`

## 💻 Uso básico

\`\`\`bash
# Listar contenido de un disco
iDSK mydisk.dsk -l

# Importar archivo al disco
iDSK mydisk.dsk -i myfile.bas

# Extraer archivo del disco
iDSK mydisk.dsk -g myfile.bas

# Crear nuevo disco
iDSK newdisk.dsk -n
\`\`\`

## 🔗 Enlaces

- [Documentación completa](https://github.com/$REPO)
- [Reportar bugs](https://github.com/$REPO/issues)
- [Contribuir](https://github.com/$REPO/pulls)

---

**Created by Destroyer 2025**"

# Guardar notas para referencia
echo "$RELEASE_NOTES" > "build/release_notes.md"

# Recopilar todos los archivos para subir
FILES_TO_UPLOAD=()

# Añadir artefactos
for file in artifacts/*.tar.gz; do
    if [ -f "$file" ]; then
        FILES_TO_UPLOAD+=("$file")
    fi
done

# Añadir bottles
for file in bottles/*.tar.gz; do
    if [ -f "$file" ]; then
        FILES_TO_UPLOAD+=("$file")
    fi
done

if [ ${#FILES_TO_UPLOAD[@]} -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron archivos para subir${NC}"
    exit 1
fi

echo -e "${BLUE}📤 Archivos a subir:${NC}"
for file in "${FILES_TO_UPLOAD[@]}"; do
    echo -e "  ${GREEN}✅${NC} $file"
done

# Crear release en GitHub
echo -e "${BLUE}🚀 Creando release en GitHub...${NC}"

gh release create "$TAG" \
    --repo "$REPO" \
    --title "Release $TAG" \
    --notes "$RELEASE_NOTES" \
    "${FILES_TO_UPLOAD[@]}"

echo -e "${GREEN}🎉 Release $TAG creado exitosamente!${NC}"

# Hacer push del tag
# echo -e "${BLUE}⬆️  Subiendo tag a repositorio...${NC}"
# git push origin "$TAG"

# Mostrar información del release
echo ""
echo -e "${GREEN}✅ Release completado${NC}"
echo -e "${GREEN}🔗 URL: https://github.com/$REPO/releases/tag/$TAG${NC}"
echo ""
echo -e "${BLUE}📊 Resumen:${NC}"
echo -e "  Tag: $TAG"
echo -e "  Artefactos: $ARTIFACTS_COUNT"
echo -e "  Bottles: $BOTTLES_COUNT"
echo -e "  Total archivos: $((ARTIFACTS_COUNT + BOTTLES_COUNT))"

# Actualizar build info
if [ -f "build/build_info.json" ]; then
    # Añadir información del release al JSON
    cat > build/release_info.json << EOF
{
  "version": "$VERSION",
  "tag": "$TAG",
  "repo": "$REPO",
  "release_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "artifacts_count": $ARTIFACTS_COUNT,
  "bottles_count": $BOTTLES_COUNT,
  "release_url": "https://github.com/$REPO/releases/tag/$TAG"
}
EOF
    echo -e "${GREEN}💾 Información guardada en build/release_info.json${NC}"
fi

echo ""
echo -e "${YELLOW}📝 Próximo paso:${NC}"
echo "./scripts/update-formula.sh $VERSION"