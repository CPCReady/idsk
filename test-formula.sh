#!/bin/bash


# Script para probar fórmula de Homebrew localmente
# Created by Destroyer 2025

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORMULA_FILE="Formula/idsk.rb"
PROJECT_NAME="iDSK"

show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --audit         Solo ejecutar audit"
    echo "  --test          Solo ejecutar tests"
    echo "  --install       Instalar fórmula"
    echo "  --full          Ejecutar audit, test e instalar"
    echo "  --setup-tap     Solo configurar el tap"
    echo "  --cleanup       Desinstalar y limpiar"
    echo "  -h, --help      Mostrar esta ayuda"
}

setup_tap() {
    # Verificar si el tap existe
    TAP_DIR="$(brew --repository)/Library/Taps/cpcready/homebrew-cpcready"
    if [ ! -d "$TAP_DIR" ]; then
        echo -e "${YELLOW}⚠️  El tap cpcready/cpcready no existe. Creándolo...${NC}"
        if ! brew tap cpcready/cpcready; then
            echo -e "${RED}❌ Error al crear el tap. Asegúrate de que tienes permisos de escritura.${NC}"
            return 1
        fi
    fi
    
    # Copiar fórmula al tap si no está actualizada
    if [ ! -f "$TAP_DIR/idsk.rb" ] || [ "$FORMULA_FILE" -nt "$TAP_DIR/idsk.rb" ]; then
        echo -e "${BLUE}📋 Copiando fórmula al tap...${NC}"
        if ! cp "$FORMULA_FILE" "$TAP_DIR/"; then
            echo -e "${RED}❌ Error al copiar la fórmula al tap${NC}"
            return 1
        fi
        echo -e "${GREEN}✅ Fórmula copiada al tap${NC}"
    else
        echo -e "${GREEN}✅ Fórmula ya está actualizada en el tap${NC}"
    fi
}

run_audit() {
    echo -e "${BLUE}🔍 Ejecutando brew audit...${NC}"
    setup_tap
    
    # Ejecutar audit usando el tap
    if brew audit cpcready/cpcready/idsk; then
        echo -e "${GREEN}✅ Audit pasado${NC}"
    else
        echo -e "${RED}❌ Audit falló${NC}"
        return 1
    fi
}

run_test() {
    echo -e "${BLUE}🧪 Ejecutando brew test...${NC}"
    setup_tap
    
    # Verificar si la fórmula está instalada, si no, instalarla
    if ! brew list cpcready/cpcready/idsk &> /dev/null; then
        echo -e "${YELLOW}⚠️  La fórmula no está instalada. Instalando primero...${NC}"
        if ! brew install --build-from-source cpcready/cpcready/idsk; then
            echo -e "${RED}❌ Error al instalar la fórmula${NC}"
            return 1
        fi
    fi
    
    # Ejecutar test usando el tap
    if brew test cpcready/cpcready/idsk; then
        echo -e "${GREEN}✅ Tests pasados${NC}"
    else
        echo -e "${RED}❌ Tests fallaron${NC}"
        return 1
    fi
}

install_formula() {
    echo -e "${BLUE}📦 Instalando fórmula desde fuente...${NC}"
    setup_tap
    
    # Verificar si ya está instalada
    if brew list cpcready/cpcready/idsk &> /dev/null; then
        echo -e "${YELLOW}⚠️  La fórmula ya está instalada. Reinstalando...${NC}"
        brew uninstall cpcready/cpcready/idsk
    fi
    
    if brew install --build-from-source cpcready/cpcready/idsk; then
        echo -e "${GREEN}✅ Instalación exitosa${NC}"
        
        # Probar comandos básicos
        echo -e "${BLUE}🔧 Probando comandos básicos...${NC}"
        if command -v "$PROJECT_NAME" &> /dev/null; then
            echo -e "${GREEN}✅ Comando $PROJECT_NAME disponible${NC}"
            
            # Probar ayuda (iDSK requiere argumentos)
            echo -e "${BLUE}❓ Probando ayuda...${NC}"
            "$PROJECT_NAME" 2>&1 | head -10
            
            # Probar funcionalidad básica
            echo -e "${BLUE}⚙️  Probando funcionalidad básica...${NC}"
            # Crear un DSK de prueba
            if "$PROJECT_NAME" /tmp/test_idsk.dsk -n 2>/dev/null; then
                echo -e "${GREEN}✅ Creación de DSK funciona${NC}"
                # Verificar que se creó el archivo
                if [ -f "/tmp/test_idsk.dsk" ]; then
                    echo -e "${GREEN}✅ Archivo DSK creado correctamente${NC}"
                    # Listar contenido del DSK vacío
                    if "$PROJECT_NAME" /tmp/test_idsk.dsk -l 2>/dev/null | grep -q "No file"; then
                        echo -e "${GREEN}✅ Listado de DSK funciona${NC}"
                    else
                        echo -e "${YELLOW}⚠️  Listado de DSK produce salida inesperada pero no falló${NC}"
                    fi
                    rm -f /tmp/test_idsk.dsk
                else
                    echo -e "${RED}❌ No se creó el archivo DSK${NC}"
                fi
            else
                echo -e "${RED}❌ Funcionalidad básica falló${NC}"
            fi
            
        else
            echo -e "${RED}❌ Comando $PROJECT_NAME no disponible después de instalación${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Instalación falló${NC}"
        return 1
    fi
}

cleanup_formula() {
    echo -e "${BLUE}🧹 Limpiando instalación...${NC}"
    if brew list idsk &> /dev/null; then
        brew uninstall idsk
        echo -e "${GREEN}✅ idsk desinstalado${NC}"
    else
        echo -e "${YELLOW}⚠️  idsk no estaba instalado${NC}"
    fi
}

# Verificar que existe la fórmula
if [ ! -f "$FORMULA_FILE" ]; then
    echo -e "${RED}❌ No se encontró $FORMULA_FILE${NC}"
    exit 1
fi

# Procesar argumentos
case "${1:-}" in
    --audit)
        run_audit
        ;;
    --test)
        run_test
        ;;
    --install)
        install_formula
        ;;
    --setup-tap)
        echo -e "${BLUE}🔧 Configurando tap...${NC}"
        setup_tap
        echo -e "${GREEN}✅ Tap configurado${NC}"
        ;;
    --full)
        echo -e "${BLUE}🚀 Ejecutando tests completos...${NC}"
        run_audit
        run_test
        install_formula
        echo -e "${GREEN}🎉 Todos los tests completados${NC}"
        ;;
    --cleanup)
        cleanup_formula
        ;;
    -h|--help)
        show_help
        ;;
    "")
        echo -e "${BLUE}🔍 Ejecutando tests básicos...${NC}"
        run_audit
        echo -e "${GREEN}✅ Tests básicos completados${NC}"
        echo ""
        echo "Para más opciones:"
        echo "  $0 --full     # Tests completos + instalación"
        echo "  $0 --help    # Ayuda completa"
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac