# catalog - Lightweight DSK Catalog Viewer

A minimal, standalone utility extracted from iDSK to display the contents of Amstrad CPC DSK disk images.

## What is this?

This is a simplified version of iDSK that contains **only** the code necessary to list the catalog of a DSK file. It's equivalent to running `iDSK floppy.dsk -l` but as a lightweight standalone tool.

## Features

- 📋 Professional table format with Unicode borders
- 📊 Simple column format option
- 💾 Shows file size, load address, execution address, and user number
- 🔍 Automatic AMSDOS header detection
- 🌐 Cross-platform (Linux, macOS, Windows)

## Build Instructions

### Using Make (Linux/macOS)

```bash
make
```

### Using CMake (all platforms)

```bash
mkdir build
cd build
cmake ..
cmake --build .
```

## Usage

```bash
# Professional table format (default)
./catalog disk.dsk

# Simple column format
./catalog disk.dsk --simple
```

## Example Output

### Table Format
```
┌──────────────┬────────┬──────────┬──────────┬────────┐
│     File     │  Size  │   Load   │   Exec   │  User  │
├──────────────┼────────┼────────┼──────────┼────────┤
│ GAME    .BAS │    2 K │  &0170   │  &0000   │   0    │
│ LOADER  .BIN │    3 K │  &8000   │  &8000   │   0    │
├──────────────────────────────────────────────────────┤
│                      173K free                       │
└──────────────────────────────────────────────────────┘
```

### Simple Format
```
GAME    .BAS    2 K   &0170    &0000    User 0
LOADER  .BIN    3 K   &8000    &8000    User 0

173K free
```

## Code Structure

- `catalog.cpp` - Main program
- `dsk.cpp` - DSK file handling and catalog reading
- `dsk.h` - DSK class interface
- `types.h` - Data structures (directory entries, AMSDOS headers)

## What's Included?

This extraction includes only the essential code:
- DSK file reading (`ReadDsk`)
- DSK format validation (`CheckDsk`)
- Directory entry parsing (`GetInfoDirEntry`)
- Block reading (`ReadBloc`)
- AMSDOS header detection and parsing
- Catalog formatting (table and simple modes)
- Free space calculation

## What's NOT Included?

Everything else from iDSK:
- File import/export
- File deletion
- BASIC file viewing
- Hexadecimal dumps
- Z80 disassembly
- Disk creation
- And more...

## Dependencies

- C++11 compatible compiler
- Standard C++ library

No external dependencies required!

## License

Same as iDSK - check the parent directory for license information.

## Comparison with iDSK

| Feature | catalog | iDSK |
|---------|---------|------|
| List directory | ✅ | ✅ |
| Binary size | ~50KB | ~200KB |
| Import files | ❌ | ✅ |
| Export files | ❌ | ✅ |
| View BASIC | ❌ | ✅ |
| Create DSK | ❌ | ✅ |

Use `catalog` when you only need to quickly view DSK contents. Use full `iDSK` for complete disk management.
