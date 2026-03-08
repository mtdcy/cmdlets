# cmdlet.bat - Windows Package Fetcher

## Overview

`cmdlet.bat` is a Windows batch script for fetching prebuilt packages from the cmdlets repository.

## Features

- ✅ Fetch packages from remote repository
- ✅ Support versioned packages (`pkg@version`)
- ✅ Support subdirectory packages (`pkgname/file`)
- ✅ Manifest-based package resolution (v3)
- ✅ Fallback to direct download (v2)
- ✅ Automatic extraction to `prebuilts/` directory
- ✅ Track installed packages in `.cmdlets` file

## Requirements

- Windows 10 or later (for ANSI color support)
- `curl.exe` (included in Windows 10+)
- `tar.exe` (included in Windows 10+)

## Usage

### Basic Fetch

```batch
REM Fetch latest version
cmdlet.bat fetch curl

REM Fetch specific version
cmdlet.bat fetch curl@8.18.0

REM Fetch from subdirectory
cmdlet.bat fetch zlib/minigzip@1.3.1
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

## Repository Format

### v3 (Manifest-based)

The script first checks for `.manifest` file in the prebuilts directory:

```
pkgname@version.tar.gz sha256 build_id
```

### v2 (Direct)

Fallback to direct download from repository:

```
<REPO>/<ARCH>/<pkgname>@<version>.tar.gz
```

## Testing

### On Windows (Native)

```batch
REM Test fetch curl
cmdlet.bat fetch curl

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
    wine cmd.exe /c cmdlet.bat fetch curl
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

## License

BSD 2-Clause License

## Author

Chen Fang <mtdcy.chen@gmail.com>
