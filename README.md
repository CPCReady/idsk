# iDSK - Amstrad CPC Disk Image Management Tool

[![L## Key Features

- 📁️ **Complete File Management**: Import, export, and delete files from disk images
- 📋 **Content Listing**: Display disk catalogs with detailed file information  
- 🔍 **File Analysis**: View BASIC programs, disassemble Z80 code, hex dumps
- 💾 **Disk Creation**: Generate new formatted DSK images
- ⚙️ **AMSDOS Headers**: Automatic handling of load/execution addresses
- 🔄 **Smart Text Conversion**: Automatic Unix to DOS line ending conversion for BASIC files (.bas)
- 🌐 **Cross-Platform**: Native support for x86, AMD64, ARM, and Apple SiliconMIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-0.20--CPCReady-green.svg)](https://github.com/cpcsdk/idsk)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20ARM-lightgrey.svg)]()
[![Build](https://img.shields.io/badge/Build-CMake-orange.svg)](https://cmake.org/)

**iDSK** is a professional command-line utility for comprehensive management of DSK (Amstrad CPC disk image) files. This cross-platform tool enables complete manipulation of virtual Amstrad CPC disks with support for all major architectures.

## 🆕 Recent Improvements (v0.20-CPCReady)

This version includes significant enhancements focused on internationalization and user experience:

### 🌍 **Complete Internationalization**
- **English Interface**: All French text converted to English for global accessibility
  - Error messages: `"Fichier image non supporté"` → `"Unsupported image file"`
  - Comments: `"Retourne la taille"` → `"Returns the file size"`
  - Debug output: `"Taille du fichier"` → `"File size"`
- **Standardized Units**: French `"Ko"` changed to universal `"K"` format
- **Professional Consistency**: Aligned with international development standards

### 📊 **Enhanced Output Format**
- **Clean Listing**: Removed unnecessary header lines (`DSK : filename`, separator lines)
- **Compact Display**: File sizes now show as `"1 K"` instead of `"1 KB"`
- **Free Space Indicator**: Live disk usage with format `"173K free"`

### 🎯 **User Experience Improvements**
- **Streamlined Output**: Focus on essential information only
- **Better Readability**: Clear visual hierarchy in file listings
- **Real-time Disk Usage**: Immediate feedback on available space
- **Cleaner Interface**: Removed redundant visual elements

### 📁 **Example Output Comparison**

**Before:**
```
DSK : test.dsk
GAME    .BAS 0
LOADER  .BIN 0
------------------------------------
```

**After:**
```

GAME    .BAS 1 K
LOADER  .BIN 1 K

176K free
```

These improvements make iDSK more accessible to international developers while providing a cleaner, more informative user interface that focuses on essential disk management information.

## Key Features

- �️ **Complete File Management**: Import, export, and delete files from disk images
- � **Content Listing**: Display disk catalogs with detailed file information  
- 🔍 **File Analysis**: View BASIC programs, disassemble Z80 code, hex dumps
- � **Disk Creation**: Generate new formatted DSK images
- ⚙️ **AMSDOS Headers**: Automatic handling of load/execution addresses
- 🌐 **Cross-Platform**: Native support for x86, AMD64, ARM, and Apple Silicon

## Quick Start

```bash
# List disk contents (default operation)
iDSK disk.dsk

# Create a new disk image
iDSK newdisk.dsk -n

# Import a file to disk
iDSK disk.dsk -i program.bas

# Export a file from disk  
iDSK disk.dsk -g program.bas

# View BASIC program (detokenized)
iDSK disk.dsk -b program.bas
```

## Build Instructions

### Prerequisites

The following tools are required for all platforms:
- **CMake** 3.10 or higher
- **C++ Compiler** with C++11 support
- **Git** (for source download)

### Platform-Specific Setup

#### Linux (x86_64/AMD64)
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y build-essential cmake git

# CentOS/RHEL/Fedora
sudo dnf install -y gcc-c++ cmake git make
# or for older versions:
sudo yum install -y gcc-c++ cmake git make
```

#### Linux ARM64 (Raspberry Pi 4/5, ARM servers)
```bash
# Raspberry Pi OS / Ubuntu ARM
sudo apt update
sudo apt install -y build-essential cmake git

# For Raspberry Pi OS Lite, may need:
sudo apt install -y g++
```

#### Linux ARM32 (Raspberry Pi 2/3/Zero)
```bash
# Raspberry Pi OS (32-bit)
sudo apt update
sudo apt install -y build-essential cmake git

# Ensure sufficient memory for compilation
sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
sudo /sbin/mkswap /var/swap.1
sudo /sbin/swapon /var/swap.1
```

#### macOS Intel (x86_64)
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install build dependencies
brew install cmake git
```

#### macOS Apple Silicon (M1/M2/M3/M4)
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew for Apple Silicon
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install build dependencies
brew install cmake git

# Verify architecture
uname -m  # Should show "arm64"
```

### Universal Build Process

The build process is identical across all platforms:

```bash
# 1. Clone the repository
git clone https://github.com/cpcsdk/idsk.git
cd idsk

# 2. Create and enter build directory
mkdir build && cd build

# 3. Configure with CMake
cmake ..

# 4. Build the project
cmake --build . --config Release

# 5. Verify the build
./iDSK --help 2>/dev/null || echo "Build completed - binary ready"
```

### Platform-Specific Build Optimizations

#### High-Performance Build (All Platforms)
```bash
# Use all available CPU cores
cmake --build . --config Release --parallel $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
```

#### ARM-Specific Optimizations
```bash
# For ARM64 (Pi 4/5, M1/M2/M3/M4)
cmake -DCMAKE_CXX_FLAGS="-O3 -mcpu=native" ..

# For ARM32 (Pi 2/3/Zero)
cmake -DCMAKE_CXX_FLAGS="-O3 -mcpu=cortex-a7 -mfpu=neon-vfpv4" ..
```

#### Installation (Optional)
```bash
# Install system-wide (requires sudo on Linux/macOS)
sudo cmake --install .

# Or copy binary manually
sudo cp iDSK /usr/local/bin/
```

### Troubleshooting Build Issues

#### Common Problems and Solutions

**Error: CMake not found**
```bash
# Linux: Install from package manager as shown above
# macOS: Install via Homebrew or download from cmake.org
```

**Error: Compiler not found**
```bash
# Linux
sudo apt install -y g++

# macOS
xcode-select --install
```

**Error: Out of memory (ARM32/Pi)**
```bash
# Increase swap space
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

**Error: Architecture mismatch (macOS)**
```bash
# Clear CMake cache and rebuild
rm -rf build
mkdir build && cd build
cmake ..
cmake --build .
```

### Cross-Compilation

#### Building ARM64 on x86_64 Linux
```bash
# Install cross-compiler
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Configure for cross-compilation
cmake -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
      -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=aarch64 ..
```

#### Building ARM32 on x86_64 Linux
```bash
# Install cross-compiler
sudo apt install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

# Configure for cross-compilation
cmake -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
      -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=arm ..
```

## Pre-built Binaries

### Download and Verify
```bash
# Download verification script
curl -O https://raw.githubusercontent.com/cpcsdk/idsk/main/scripts/verify-checksums.sh
chmod +x verify-checksums.sh

# Download and verify latest release (replace with your platform)
./verify-checksums.sh --download-and-verify v0.20-CPCReady linux-amd64

# Or verify existing downloaded files
./verify-checksums.sh idsk-linux-amd64 checksums.txt
```

### Available Platforms
Pre-built binaries are available for all releases:
- `idsk-linux-amd64` - Linux x86_64 (Intel/AMD)
- `idsk-linux-arm64` - Linux ARM64 (Raspberry Pi 4/5, ARM servers)
- `idsk-linux-arm32` - Linux ARM32 (Raspberry Pi 2/3/Zero)
- `idsk-macos-intel` - macOS x86_64 (Intel Macs)
- `idsk-macos-arm64` - macOS ARM64 (Apple Silicon M1/M2/M3/M4)

### Automated Builds
GitHub Actions automatically builds and tests all platforms:
- **Continuous Integration**: Every push and pull request
- **Multi-platform builds**: All supported architectures
- **Security scanning**: Weekly automated security analysis
- **Checksum generation**: SHA-256, MD5, and integrity verification

## Usage Reference

### Command Syntax
```
iDSK <dsk_file> [OPTIONS] [files...]
```

### Core Operations

| Command | Description | Example |
|---------|-------------|---------|
| `(none)` | **List disk catalog** (default) | `iDSK disk.dsk` |
| `-l` | **List disk catalog** (explicit) | `iDSK disk.dsk -l` |
| `-n` | **Create new disk** image | `iDSK new.dsk -n` |
| `-i <files>` | **Import files** to disk | `iDSK disk.dsk -i prog.bas` |
| `-g <files>` | **Get/export files** from disk | `iDSK disk.dsk -g prog.bas` |
| `-r <files>` | **Remove files** from disk | `iDSK disk.dsk -r prog.bas` |

### File Viewing Operations

| Command | Description | Example |
|---------|-------------|---------|
| `-b <files>` | **View BASIC program** (detokenized) | `iDSK disk.dsk -b game.bas` |
| `-a <files>` | **View ASCII file** | `iDSK disk.dsk -a readme.txt` |
| `-h <files>` | **View file as hexadecimal** | `iDSK disk.dsk -h data.bin` |
| `-z <files>` | **Disassemble binary** (Z80) | `iDSK disk.dsk -z code.bin` |
| `-d <files>` | **View DAMS file** | `iDSK disk.dsk -d source.dms` |

### Import Modifiers

These options modify the behavior of the `-i` (import) command:

| Option | Parameter | Description | Example |
|--------|-----------|-------------|---------|
| `-t` | `0\|1\|2` | **File type**: 0=ASCII, 1=Binary, 2=Raw | `-i file.bin -t 1` |
| `-c` | `address` | **Load address** (hexadecimal) | `-i file.bin -c 8000` |
| `-e` | `address` | **Execution address** (hexadecimal) | `-i file.bin -e C000` |
| `-u` | `0-15` | **User number** | `-i file.bas -u 1` |
| `-f` | - | **Force overwrite** existing files | `-i file.bas -f` |
| `-o` | - | **Read-only** file attribute | `-i file.bas -o` |
| `-s` | - | **System** file attribute | `-i file.bin -s` |

### Display Modifiers

| Option | Description | Example |
|--------|-------------|---------|
| `-p` | **Split long lines** at 80 characters | `-b program.bas -p` |

## Usage Examples

### Basic Disk Operations

```bash
# Create a new formatted disk
iDSK mydisk.dsk -n

# List the contents (should be empty)
iDSK mydisk.dsk

# Import a BASIC program
iDSK mydisk.dsk -i game.bas -t 0

# Import a binary with specific load/exec addresses
iDSK mydisk.dsk -i loader.bin -t 1 -c 8000 -e 8000

# View the updated disk contents
iDSK mydisk.dsk -l
```

### File Management

```bash
# Export a file from disk to current directory
iDSK source.dsk -g program.bas

# Remove a file from disk
iDSK source.dsk -r oldfile.bas

# Import with force overwrite (no confirmation)
iDSK target.dsk -i program.bas -t 0 -f
```

### Content Analysis

```bash
# View BASIC program source code
iDSK game.dsk -b menu.bas

# View binary file in hexadecimal
iDSK game.dsk -h sprites.bin

# Disassemble Z80 machine code
iDSK game.dsk -z routine.bin

# View text file contents
iDSK data.dsk -a readme.txt
```

### Advanced Import Examples

```bash
# Import binary as system file, read-only, user 0
iDSK system.dsk -i firmware.bin -t 1 -c C000 -e C000 -u 0 -s -o

# Import BASIC program with line splitting for display
iDSK disk.dsk -i longprog.bas -t 0
iDSK disk.dsk -b longprog.bas -p

# Import raw data file
iDSK disk.dsk -i graphics.dat -t 2 -c 4000
```

### Batch Operations

```bash
# Export multiple files (requires separate commands)
iDSK source.dsk -g file1.bas
iDSK source.dsk -g file2.bin  
iDSK source.dsk -g file3.txt

# Import multiple files with different types
iDSK target.dsk -i menu.bas -t 0
iDSK target.dsk -i loader.bin -t 1 -c 8000 -e 8000
iDSK target.dsk -i data.txt -t 0
```

## Technical Specifications

### Supported File Types

| Type | Value | Description | Typical Use |
|------|-------|-------------|-------------|
| ASCII | `0` | Text files | BASIC programs, documentation |
| Binary | `1` | Executable files | Machine code, compiled programs |
| Raw | `2` | Data without AMSDOS header | Graphics, sound data |

### Text File Conversion

When importing BASIC files with `.bas` extension (case-insensitive) in ASCII mode (`-t 0`), iDSK automatically converts Unix line endings (`\n`) to DOS format (`\r\n`) for Amstrad CPC compatibility:

```bash
# BASIC files with any case extension get automatically converted
iDSK disk.dsk -i program.bas -t 0    # .bas
iDSK disk.dsk -i PROGRAM.BAS -t 0    # .BAS  
iDSK disk.dsk -i Program.Bas -t 0    # .Bas

# Other ASCII files maintain original line endings
iDSK disk.dsk -i readme.txt -t 0

# Binary files preserve original byte content
iDSK disk.dsk -i executable.bin -t 1

# Raw files maintain exact byte sequence  
iDSK disk.dsk -i data.raw -t 2
```

**Important**: This conversion only affects BASIC files (`.bas` extension, case-insensitive) in ASCII mode (`-t 0`). Other file types and modes preserve all bytes exactly as stored to maintain file integrity.

### Memory Address Format

Addresses are specified in **hexadecimal** without prefix:

| Address | Decimal | Typical Use |
|---------|---------|-------------|
| `1000` | 4096 | Low memory programs |
| `8000` | 32768 | Standard user area |
| `C000` | 49152 | High memory area |

### Disk Format

- **Format**: CPCEMU DSK standard
- **Capacity**: 178KB (40 tracks × 9 sectors × 512 bytes)
- **File System**: CP/M compatible with AMSDOS extensions
- **Max Files**: 64 directory entries

### AMSDOS Headers

Binary files can include 128-byte headers containing:
- Load address (where to place in memory)
- Execution address (program entry point)  
- File length and checksum
- File type and attributes

## Automation Scripts

iDSK includes several automation scripts to streamline common tasks:

### Disk Documentation Generator

The `generate-disk-readme.sh` script automatically analyzes DSK files and creates comprehensive documentation:

```bash
# Generate documentation for a disk
./scripts/generate-disk-readme.sh game.dsk

# Verbose output with detailed analysis
./scripts/generate-disk-readme.sh game.dsk --verbose

# Custom output filename
./scripts/generate-disk-readme.sh game.dsk --output documentation.txt
```

**Features:**
- Automatic file type detection (BASIC, binary, text)
- BASIC program analysis with content preview
- Binary file hex dump analysis
- Usage instructions for each file type
- Technical disk information and compatibility notes

**Output includes:**
- Complete file listing with descriptions
- BASIC program summaries and line counts
- Binary file analysis and machine code detection
- Usage instructions for emulators
- Technical specifications

### Release Management

```bash
# Generate checksums for release files
./scripts/verify-checksums.sh

# Create release package (used by GitHub Actions)
./scripts/release.sh
```

All scripts are located in the `scripts/` directory and include built-in help:

```bash
./scripts/generate-disk-readme.sh --help
```

## Error Handling

### Common Error Messages

**"Error reading file"**
- File doesn't exist or is corrupted
- Check file path and permissions

**"Unsupported dsk file"**  
- Not a valid CPCEMU DSK format
- Use a different disk image tool to convert

**"File not found"**
- File doesn't exist in the disk image
- Use `-l` to list available files

**"File exists, replace?"**
- Target file already exists
- Use `-f` to force overwrite

### Return Codes

- `0` - Success
- `1` - Error (file not found, invalid disk, etc.)

---

**iDSK v0.20-CPCReady** - Professional Amstrad CPC disk image management  
*Part of the CPCSDK toolchain - https://github.com/cpcsdk*
