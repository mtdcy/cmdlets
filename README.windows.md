# cmdlets.bat - Windows Package Manager

## Overview

`cmdlets.bat` is a Windows batch script for managing prebuilt packages from the cmdlets repository.

## Features

- ✅ Fetch packages from remote repository
- ✅ List installed packages and files
- ✅ Search for packages
- ✅ Remove installed packages
- ✅ Support versioned packages (`pkg@version`)
- ✅ Support subdirectory packages (`pkgname/file`)
- ✅ Manifest-based package resolution (v3)
- ✅ Fallback to direct download (v2)
- ✅ Automatic extraction to `prebuilts/` directory
- ✅ Track installed packages in `.cmdlets` file

## Quick Start

### 1. Bootstrap (Linux/macOS)

```bash
./bootstrap.windows.sh
```

This downloads Windows (mingw64) versions of:
- `curl.exe` - for downloading packages
- `tar.exe` (from bsdtar) - for extracting packages

Then copy the `prebuilts/` directory to your Windows environment.

### 2. Using cmdlets.bat (Windows)

```batch
cmdlets.bat fetch curl
cmdlets.bat list
cmdlets.bat search curl
cmdlets.bat remove curl
```

---

## Requirements

- Windows 7 or later
- `curl.exe` - for downloading packages
- `tar.exe` or `bsdtar.exe` - for extracting packages

## Usage

### Fetch Package

```batch
REM Fetch latest version
cmdlets.bat fetch curl

REM Fetch specific version
cmdlets.bat fetch curl@8.18.0

REM Fetch from subdirectory
cmdlets.bat fetch zlib/minigzip@1.3.1
```

### List Installed Packages

```batch
REM List all installed packages
cmdlets.bat list

REM List files for specific package
cmdlets.bat list curl
```

### Search Packages

```batch
REM Search for packages
cmdlets.bat search curl
```

### Remove Package

```batch
REM Remove installed package
cmdlets.bat remove curl
```

### Environment Variables

```batch
REM Set custom repository
set REPO=https://github.com/mtdcy/cmdlets/releases/download

REM Set target architecture
set ARCH=x86_64-windows-gnu

REM Set installation directory
set PREBUILTS=C:\path\to\prebuilts
```

## Commands

| Command | Description |
|---------|-------------|
| `fetch <cmdlet>` | Download and extract cmdlet package |
| `list [cmdlet]` | List installed packages or files |
| `search <pattern>` | Search for packages |
| `remove <cmdlet>` | Remove installed package |
| `help` | Show help message |

## Repository Format

### v3 (Manifest-based)

The script first checks for `.manifest` file in the prebuilts directory:

```
pkgname@version.tar.gz sha256 build_id
```

### v2 (Direct)

Fallback to direct download from repository:

```
<REPO>/<ARCH>/<pkgname>/<pkgname>@<version>.tar.gz
```

## Testing

### On Windows (Native)

```batch
REM Test fetch curl
cmdlets.bat fetch curl

REM List installed packages
cmdlets.bat list

REM Search for packages
cmdlets.bat search curl

REM Remove package
cmdlets.bat remove curl

REM Check results
dir prebuilts\bin
type prebuilts\.cmdlets
```

### On Linux/macOS (Cross-compile test)

```bash
# Using Docker with Wine
./test-cmdlet.bat.sh curl

# Manual test
docker run --rm --platform linux/amd64 \
    -v $(pwd)/test-win:/workspace \
    -w /workspace \
    lcr.io/mtdcy/builder:mingw64-latest \
    wine cmd.exe /c cmdlets.bat fetch curl
```

## Output Structure

```
prebuilts/
├── bin/           # Executables
├── lib/           # Libraries
├── include/       # Headers
├── share/         # Data files
├── .cmdlets       # Installed packages list
└── .manifest      # Package manifest (optional)
```

## Limitations

- ❌ No SHA256 verification (TODO)
- ❌ No symlink creation (handled by build system)
- ❌ No dependency resolution (manual installation required)

## Troubleshooting

### "curl not found"

Ensure `curl.exe` is in your PATH (Windows 10+ includes it by default).

### "tar not found"

Ensure `tar.exe` is in your PATH (Windows 10+ includes it by default).

### "Manifest not found"

This is normal for first-time use. The script will fallback to direct download.

### "Package not found"

Check the repository URL for available packages:
```
https://pub.mtdcy.top/cmdlets/latest/x86_64-w64-mingw32/
```

## License

BSD 2-Clause License

## Author

Chen Fang <mtdcy.chen@gmail.com>
