#!/bin/bash
# iDSK Checksum Verification Script
# Usage: ./scripts/verify-checksums.sh [binary_file] [checksums_file]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "iDSK Checksum Verification Script"
    echo ""
    echo "Usage: $0 [binary_file] [checksums_file]"
    echo "       $0 --download-and-verify [version] [platform]"
    echo ""
    echo "Arguments:"
    echo "  binary_file     Path to iDSK binary to verify"
    echo "  checksums_file  Path to checksums file (optional, will look for common names)"
    echo ""
    echo "Options:"
    echo "  --download-and-verify  Download and verify release from GitHub"
    echo "  --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 idsk-linux-amd64"
    echo "  $0 idsk-macos-arm64 checksums.txt"
    echo "  $0 --download-and-verify v0.21 linux-amd64"
    echo ""
    echo "Supported platforms for download:"
    echo "  linux-amd64, linux-arm64, linux-arm32, macos-intel, macos-arm64"
}

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_dependencies() {
    local missing_deps=()
    
    # Check for required tools
    command -v sha256sum >/dev/null 2>&1 || {
        if command -v shasum >/dev/null 2>&1; then
            SHA256_CMD="shasum -a 256"
        else
            missing_deps+=("sha256sum or shasum")
        fi
    }
    SHA256_CMD=${SHA256_CMD:-sha256sum}
    
    command -v md5sum >/dev/null 2>&1 || {
        if command -v md5 >/dev/null 2>&1; then
            MD5_CMD="md5 -r"
        else
            missing_deps+=("md5sum or md5")
        fi
    }
    MD5_CMD=${MD5_CMD:-md5sum}
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing required dependencies: ${missing_deps[*]}"
    fi
}

verify_file() {
    local binary_file="$1"
    local checksums_file="$2"
    
    if [ ! -f "$binary_file" ]; then
        error "Binary file not found: $binary_file"
    fi
    
    log "Verifying checksums for: $binary_file"
    
    # Find checksums file if not provided
    if [ -z "$checksums_file" ]; then
        local possible_names=(
            "checksums.txt"
            "CHECKSUMS.txt"
            "${binary_file}.sha256"
            "${binary_file}.md5"
            "$(dirname "$binary_file")/checksums.txt"
        )
        
        for name in "${possible_names[@]}"; do
            if [ -f "$name" ]; then
                checksums_file="$name"
                log "Found checksums file: $checksums_file"
                break
            fi
        done
        
        if [ -z "$checksums_file" ]; then
            warn "No checksums file found. Looking for individual checksum files..."
            verify_individual_checksums "$binary_file"
            return
        fi
    fi
    
    if [ ! -f "$checksums_file" ]; then
        error "Checksums file not found: $checksums_file"
    fi
    
    # Verify checksums
    local verified=false
    
    # Try SHA-256
    if grep -q "$binary_file" "$checksums_file" && grep -q "sha256\|SHA256" "$checksums_file"; then
        log "Verifying SHA-256 checksum..."
        local expected_sha256=$(grep "$binary_file" "$checksums_file" | grep -E "(sha256|SHA256)" | awk '{print $1}')
        local actual_sha256=$($SHA256_CMD "$binary_file" | awk '{print $1}')
        
        if [ "$expected_sha256" = "$actual_sha256" ]; then
            success "SHA-256 checksum verified ✓"
            verified=true
        else
            error "SHA-256 checksum mismatch!"
        fi
    fi
    
    # Try MD5
    if grep -q "$binary_file" "$checksums_file" && grep -q "md5\|MD5" "$checksums_file"; then
        log "Verifying MD5 checksum..."
        local expected_md5=$(grep "$binary_file" "$checksums_file" | grep -E "(md5|MD5)" | awk '{print $1}')
        local actual_md5=$($MD5_CMD "$binary_file" | awk '{print $1}')
        
        if [ "$expected_md5" = "$actual_md5" ]; then
            success "MD5 checksum verified ✓"
            verified=true
        else
            error "MD5 checksum mismatch!"
        fi
    fi
    
    # Try direct verification (standard format)
    if ! $verified; then
        log "Trying direct checksum verification..."
        
        # Try SHA-256 first
        if echo "$checksums_file" | grep -q sha256 || grep -qE "^[a-f0-9]{64}" "$checksums_file"; then
            if $SHA256_CMD -c "$checksums_file" 2>/dev/null; then
                success "SHA-256 checksum verified using standard format ✓"
                verified=true
            fi
        fi
        
        # Try MD5
        if ! $verified && (echo "$checksums_file" | grep -q md5 || grep -qE "^[a-f0-9]{32}" "$checksums_file"); then
            if $MD5_CMD -c "$checksums_file" 2>/dev/null; then
                success "MD5 checksum verified using standard format ✓"
                verified=true
            fi
        fi
    fi
    
    if ! $verified; then
        error "Could not verify checksums. Check that the checksums file contains the correct format."
    fi
}

verify_individual_checksums() {
    local binary_file="$1"
    local basename=$(basename "$binary_file")
    local dirname=$(dirname "$binary_file")
    
    local verified=false
    
    # Look for individual checksum files
    for ext in sha256 sha1 md5; do
        local checksum_file="${dirname}/${basename}.${ext}"
        if [ -f "$checksum_file" ]; then
            log "Found $ext checksum file: $checksum_file"
            
            case $ext in
                sha256)
                    if $SHA256_CMD -c "$checksum_file" 2>/dev/null; then
                        success "SHA-256 checksum verified ✓"
                        verified=true
                    fi
                    ;;
                md5)
                    if $MD5_CMD -c "$checksum_file" 2>/dev/null; then
                        success "MD5 checksum verified ✓"
                        verified=true
                    fi
                    ;;
            esac
        fi
    done
    
    if ! $verified; then
        warn "No individual checksum files found"
        log "Generating checksums for manual verification:"
        echo "SHA-256: $($SHA256_CMD "$binary_file")"
        echo "MD5:     $($MD5_CMD "$binary_file")"
    fi
}

download_and_verify() {
    local version="$1"
    local platform="$2"
    
    if [ -z "$version" ] || [ -z "$platform" ]; then
        error "Version and platform are required for download mode"
    fi
    
    # Validate platform
    case $platform in
        linux-amd64|linux-arm64|linux-arm32|macos-intel|macos-arm64)
            ;;
        *)
            error "Unsupported platform: $platform"
            ;;
    esac
    
    local binary_name="idsk-$platform"
    local base_url="https://github.com/cpcsdk/idsk/releases/download/$version"
    
    log "Downloading iDSK $version for $platform..."
    
    # Check if curl or wget is available
    if command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl -L -O"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
    
    # Download binary
    log "Downloading $binary_name..."
    $DOWNLOAD_CMD "$base_url/$binary_name" || error "Failed to download binary"
    
    # Download checksums
    log "Downloading checksums.txt..."
    $DOWNLOAD_CMD "$base_url/checksums.txt" || error "Failed to download checksums"
    
    # Verify
    verify_file "$binary_name" "checksums.txt"
    
    # Make executable
    chmod +x "$binary_name"
    success "Download and verification complete!"
    
    log "You can now use: ./$binary_name"
    log "Or install system-wide: sudo mv $binary_name /usr/local/bin/idsk"
}

# Main script
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

check_dependencies

case $1 in
    --help)
        usage
        exit 0
        ;;
    --download-and-verify)
        download_and_verify "$2" "$3"
        ;;
    *)
        verify_file "$1" "$2"
        ;;
esac