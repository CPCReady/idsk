#!/bin/bash
# iDSK Release Management Script
# Usage: ./scripts/release.sh [version] [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_BRANCH="main"
CURRENT_BRANCH=$(git branch --show-current)

usage() {
    echo "Usage: $0 [version] [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be done without making changes"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 v0.21                # Create release v0.21"
    echo "  $0 v0.21 --dry-run      # Show what would happen"
    echo ""
    echo "Version format should be: vX.Y[.Z] (e.g., v0.21, v1.0.0)"
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

# Parse arguments
VERSION=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        v*.*)
            VERSION=$1
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    error "Version is required. Use --help for usage information."
fi

# Validate version format
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    error "Invalid version format. Use vX.Y or vX.Y.Z (e.g., v0.21, v1.0.0)"
fi

log "Starting release process for version: $VERSION"
log "Dry run mode: $DRY_RUN"

# Pre-flight checks
log "Running pre-flight checks..."

# Check if on main branch
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    warn "Not on $DEFAULT_BRANCH branch (currently on $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Aborted by user"
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    error "Uncommitted changes detected. Please commit or stash them first."
fi

# Check if tag already exists
if git tag -l | grep -q "^$VERSION$"; then
    error "Tag $VERSION already exists"
fi

# Check if remote is accessible
if ! git ls-remote --exit-code origin >/dev/null 2>&1; then
    error "Cannot access remote repository"
fi

# Update version in source files
log "Updating version in source files..."

VERSION_NUM=${VERSION#v}  # Remove 'v' prefix
VERSION_DEFINE="#define VERSION \"iDSK version $VERSION_NUM\""

if [ "$DRY_RUN" = true ]; then
    log "Would update src/Main.h with: $VERSION_DEFINE"
else
    # Update Main.h
    if [ -f "src/Main.h" ]; then
        sed -i.bak "s/#define VERSION.*/$VERSION_DEFINE/" src/Main.h
        rm src/Main.h.bak 2>/dev/null || true
        log "Updated version in src/Main.h"
    else
        warn "src/Main.h not found"
    fi
fi

# Test build
log "Testing build process..."

if [ "$DRY_RUN" = true ]; then
    log "Would run test build"
else
    mkdir -p build-test
    cd build-test
    cmake -DCMAKE_BUILD_TYPE=Release ..
    cmake --build . --parallel $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # Basic smoke test
    if ./iDSK 2>&1 | grep -q "iDSK"; then
        success "Build test passed"
    else
        error "Build test failed"
    fi
    cd ..
    rm -rf build-test
fi

# Generate changelog entry
log "Generating changelog information..."

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    log "Changes since $LAST_TAG:"
    if [ "$DRY_RUN" = true ]; then
        git log --oneline "$LAST_TAG"..HEAD | head -10
    else
        git log --oneline "$LAST_TAG"..HEAD > /tmp/changelog-$VERSION.txt
        log "Changelog saved to /tmp/changelog-$VERSION.txt"
    fi
else
    log "No previous tags found"
fi

# Create and push tag
log "Creating and pushing tag..."

if [ "$DRY_RUN" = true ]; then
    log "Would create tag: $VERSION"
    log "Would push to origin"
else
    # Commit version changes if any
    if ! git diff-index --quiet HEAD --; then
        git add src/Main.h
        git commit -m "Bump version to $VERSION"
        log "Committed version bump"
    fi
    
    # Create annotated tag
    git tag -a "$VERSION" -m "Release $VERSION"
    success "Created tag: $VERSION"
    
    # Push changes and tag
    git push origin "$CURRENT_BRANCH"
    git push origin "$VERSION"
    success "Pushed tag to origin"
fi

# Platform-specific build instructions
log "Multi-platform build will be triggered by GitHub Actions"
log "Monitor the build at: https://github.com/cpcsdk/idsk/actions"

# Generate release notes template
RELEASE_NOTES_FILE="/tmp/release-notes-$VERSION.txt"
if [ "$DRY_RUN" = true ]; then
    log "Would generate release notes template"
else
    cat > "$RELEASE_NOTES_FILE" << EOF
# iDSK $VERSION Release Notes

## Changes in this release

$(if [ -f "/tmp/changelog-$VERSION.txt" ]; then
    echo "### Commits:"
    cat "/tmp/changelog-$VERSION.txt" | sed 's/^/- /'
else
    echo "- [Add your changes here]"
fi)

## Downloads

The following binaries are available for this release:

- **idsk-linux-amd64** - Linux x86_64 (Intel/AMD 64-bit)
- **idsk-linux-arm64** - Linux ARM64 (Raspberry Pi 4/5, ARM servers)  
- **idsk-linux-arm32** - Linux ARM32 (Raspberry Pi 2/3/Zero)
- **idsk-macos-intel** - macOS Intel (x86_64)
- **idsk-macos-arm64** - macOS Apple Silicon (M1/M2/M3/M4)

## Installation

1. Download the appropriate binary for your platform
2. Verify checksum: \`sha256sum -c checksums.txt\`
3. Make executable: \`chmod +x idsk-*\`
4. Install: \`sudo mv idsk-* /usr/local/bin/idsk\`

## Verification

All binaries include SHA-256 and MD5 checksums for verification.
See \`checksums.txt\` for complete checksum information.

---

**Full documentation**: https://github.com/cpcsdk/idsk/blob/main/README.md
EOF
    
    log "Release notes template created: $RELEASE_NOTES_FILE"
fi

# Summary
success "Release process completed!"
echo ""
log "Next steps:"
echo "  1. Monitor GitHub Actions build: https://github.com/cpcsdk/idsk/actions"
echo "  2. Once builds complete, edit the release on GitHub"
if [ "$DRY_RUN" = false ]; then
    echo "  3. Use release notes template: $RELEASE_NOTES_FILE"
fi
echo "  4. Announce the release"
echo ""
log "Release URL will be: https://github.com/cpcsdk/idsk/releases/tag/$VERSION"