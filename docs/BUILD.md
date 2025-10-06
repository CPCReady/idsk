# Build Configuration and Platform Notes

## Supported Platforms and Architectures

This document describes the build matrix and platform-specific optimizations for iDSK.

### Linux x86_64 (AMD64)
- **Target**: Standard Intel/AMD 64-bit systems
- **Compiler**: GCC 9+ or Clang 10+
- **Optimizations**: `-O3 -march=x86-64`
- **Testing**: Ubuntu 20.04, 22.04, Debian 11+, CentOS 8+

### Linux ARM64 (AArch64)
- **Target**: Raspberry Pi 4/5, ARM servers, AWS Graviton
- **Compiler**: GCC aarch64-linux-gnu cross-compiler
- **Optimizations**: `-O3 -mcpu=cortex-a72` (Pi 4/5 optimized)
- **Testing**: Raspberry Pi OS 64-bit, Ubuntu ARM64

### Linux ARM32 (ARMv7)
- **Target**: Raspberry Pi 2/3/Zero, older ARM devices
- **Compiler**: GCC arm-linux-gnueabihf cross-compiler  
- **Optimizations**: `-O3 -mcpu=cortex-a7 -mfpu=neon-vfpv4`
- **Memory**: Requires swap for compilation on 1GB devices
- **Testing**: Raspberry Pi OS 32-bit

### macOS Intel (x86_64)
- **Target**: Intel-based Macs (2006-2020)
- **Compiler**: Xcode Clang
- **Minimum**: macOS 10.14 Mojave
- **Optimizations**: `-O3 -march=core2` (compatibility)
- **Testing**: macOS 12.x, 13.x

### macOS Apple Silicon (ARM64)
- **Target**: M1, M2, M3, M4 Macs (2020+)
- **Compiler**: Xcode Clang with ARM64 support
- **Minimum**: macOS 11.0 Big Sur
- **Optimizations**: `-O3 -mcpu=apple-m1`
- **Testing**: macOS 13.x, 14.x

## Build Optimizations by Platform

### Memory-Constrained Devices (Raspberry Pi)
```bash
# Enable swap before building
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Build with reduced parallelism
cmake --build . --parallel 2
```

### High-Performance Build (Multi-core systems)
```bash
# Use all available cores
cmake --build . --parallel $(nproc)

# LTO for maximum optimization (increases build time)
cmake -DCMAKE_CXX_FLAGS="-O3 -flto" ..
```

### Debug Build for Development
```bash
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="-g -O0 -fsanitize=address" ..
```

## Cross-Compilation Setup

### Building ARM64 on x86_64 Linux
```bash
# Install cross-compilation toolchain
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Configure CMake
cmake -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
      -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
      -DCMAKE_CXX_FLAGS="-O3 -mcpu=cortex-a72" ..
```

### Building ARM32 on x86_64 Linux
```bash
# Install cross-compilation toolchain
sudo apt install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

# Configure CMake
cmake -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
      -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=arm \
      -DCMAKE_CXX_FLAGS="-O3 -mcpu=cortex-a7 -mfpu=neon" ..
```

## Performance Benchmarks

Typical build times on different platforms:

| Platform | CPU | RAM | Build Time | Binary Size |
|----------|-----|-----|------------|-------------|
| Linux x86_64 | Intel i7-10700K | 16GB | ~30s | ~150KB |
| Linux ARM64 | Pi 4 4GB | 4GB | ~3min | ~180KB |
| Linux ARM32 | Pi 3 1GB | 1GB+swap | ~8min | ~160KB |
| macOS Intel | MacBook Pro 2019 | 16GB | ~25s | ~140KB |
| macOS ARM64 | MacBook Air M1 | 8GB | ~15s | ~130KB |

## Troubleshooting

### Common Build Issues

**Error: Compiler not found**
```bash
# Linux: Install build tools
sudo apt install build-essential

# macOS: Install Xcode tools
xcode-select --install
```

**Error: CMake version too old**
```bash
# Install newer CMake from official site or:
pip3 install cmake
```

**Error: Out of memory (ARM32)**
```bash
# Increase swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Error: Cross-compilation fails**
```bash
# Clean and retry
rm -rf build
mkdir build && cd build
# Reconfigure with correct toolchain
```

### Binary Verification

After building, verify the binary:
```bash
# Check architecture
file iDSK

# Check dependencies (Linux)
ldd iDSK

# Check dependencies (macOS)
otool -L iDSK

# Run basic test
./iDSK 2>&1 | head -5
```

## GitHub Actions Integration

The project uses three workflow files:

1. **build-multiplatform.yml**: Main build matrix for all platforms
2. **ci-tests.yml**: Continuous integration and testing
3. **security-checksums.yml**: Security analysis and checksum validation

### Workflow Triggers

- **Push**: All workflows run on main/master/develop branches
- **Pull Request**: CI tests run for validation
- **Tags**: Full release build with checksums and security scan
- **Schedule**: Weekly security scans
- **Manual**: All workflows can be triggered manually

### Artifact Management

- **Development builds**: Retained for 7 days
- **Release builds**: Retained for 90 days
- **Security reports**: Retained for 30 days
- **Checksums**: Included with all builds

## Release Process

Use the provided release script:
```bash
# Create new release
./scripts/release.sh v0.21

# Dry run (test without changes)
./scripts/release.sh v0.21 --dry-run
```

The script will:
1. Validate version format and repository state
2. Update version in source code
3. Run test build
4. Create and push Git tag
5. Trigger GitHub Actions build
6. Generate release notes template

## Security Considerations

- All builds use latest compiler versions with security flags
- Static analysis runs on every build
- Dependencies are minimal (C++ standard library only)
- Cross-compilation uses official toolchains
- Checksums are generated and verified automatically
- Binary analysis checks for security features