# Status Quo — Machine Configuration Audit
**Date:** 2026-04-02
**Purpose:** Full dependency check before build work begins. Like `./configure` —
find what exists, what's missing, what blocks progress, and what to do about it.

---

## System

| Property | Value | Status |
|---|---|---|
| OS | Windows 10 Home Single Language 22H2 | ✓ |
| Build | 10.0.19045 | ✓ |
| Architecture | x86_64 (64-bit) | ✓ |
| Logical CPUs | 4 | ✓ |
| Total RAM | 6,361,997,312 bytes (~6 GB) | ⚠ tight for heavy builds |
| Free RAM | ~843 MB at audit time | ⚠ low — close other apps when compiling |
| Shell | Git Bash MINGW64 3.6.6 | ✓ |
| PowerShell | 5.1.19041.6456 | ✓ |
| User | ACER | ✓ |
| Machine | DESKTOP-ICIQ279 | ✓ |

---

## Dependency Matrix

### Legend
| Symbol | Meaning |
|---|---|
| ✓ INSTALLED | Present, verified, version known |
| ⚠ PARTIAL | Present but incomplete or stub only |
| ✗ MISSING | Not found — needs to be installed |
| 🔴 BLOCKING | Missing AND required by something that exists |
| → NEXT | First unblocked action to take |

---

### Version Control

| Tool | Status | Version | Notes |
|---|---|---|---|
| `git` | ✓ INSTALLED | 2.53.0.windows.2 | Git for Windows (MINGW64). Configured for mstcroix. |
| `gh` (GitHub CLI) | ✓ INSTALLED | 2.89.0 | Authenticated as mstcroix. Scopes: gist, read:org, repo. |
| GitHub remote | ✓ LIVE | — | github.com/mstcroix/Zr — 12 commits on master |

---

### Package Managers (Windows-side)

| Tool | Status | Version | Notes |
|---|---|---|---|
| `winget` | ✓ INSTALLED | v1.28.220 | Native Windows. Primary installer. |
| `scoop` | ✗ MISSING | — | Not needed yet. Would add if winget gaps appear. |
| `choco` | ✗ MISSING | — | Not needed. Winget covers our use cases. |

---

### Runtimes

| Tool | Status | Version | Notes |
|---|---|---|---|
| Python | ⚠ PARTIAL | — | WindowsApps stub only. `python` command redirects to MS Store. No real interpreter. |
| Python (WSL2) | ✗ MISSING | — | Will build from source (CPython) inside WSL2. Chapter 3. |
| Node.js | ✗ MISSING | — | Not installed. Not yet needed. |
| Ruby | ✗ MISSING | — | Not installed. Not needed. |

---

### Build Toolchain

| Tool | Status | Version | Notes |
|---|---|---|---|
| `gcc` / `g++` | ✗ MISSING | — | No C compiler on Windows-side. Will install inside WSL2. |
| `make` | ✗ MISSING | — | No GNU make. Will come with WSL2 build-essential. |
| `cmake` | ✗ MISSING | — | Not installed. Needed for some projects. WSL2 first. |
| `ninja` | ✗ MISSING | — | Not installed. Fast build backend for cmake. WSL2. |
| `clang` | ✗ MISSING | — | Not installed. Will assess after gcc baseline. |

---

### System Utilities

| Tool | Status | Version | Notes |
|---|---|---|---|
| `curl` | ✓ INSTALLED | 8.18.0 | Bundled with Git for Windows (mingw64). Also at System32. |
| `ssh` | ✓ INSTALLED | OpenSSH 10.2p1 | Windows built-in OpenSSH. OpenSSL 3.5.5. |
| `openssl` | ✓ INSTALLED | 3.5.5 (2026-01-27) | Bundled with Git for Windows. |
| `jq` | 🔴 BLOCKING | — | JSON processor. **Required by doc.cmd.exe.** Must install next. |
| `awk` | ✓ INSTALLED | — | Bundled with Git for Windows. Used by doc.git.hook-commit.exe. |
| `diff` | ✓ INSTALLED | — | Bundled with Git for Windows. Used by hook. |

---

### WSL / Linux Subsystem

| Component | Status | Notes |
|---|---|---|
| `wsl.exe` | ⚠ PARTIAL | Stub binary present (Windows ships it). No Linux kernel. |
| WSL Feature | ⚠ UNKNOWN | Cannot check without admin elevation. Likely disabled. |
| Ubuntu distro | ✗ MISSING | No distributions registered (LXSS registry key absent). |
| Linux kernel | ✗ MISSING | Not downloaded yet. |

---

### Project Tooling (this repo)

| File | Status | Notes |
|---|---|---|
| `doc.git.hook-commit.exe` | ✓ WORKING | Pre-commit hook. Auto-updates README Journal Entries. |
| `doc.companion.html` | ✓ WORKING | Interactive MD viewer + CLAUDE.md wizard. |
| `doc.companion.server.ps1` | ✓ WORKING | PowerShell HTTP server. Serves companion at localhost:7000. |
| `doc.cmd.exe` | 🔴 BLOCKED | Command database tool. **Requires jq.** Cannot run yet. |
| `log.commands.json` | ✓ EXISTS | 22 commands recorded. Manually maintained until jq installed. |

---

## Dependency Graph

```
WSL2 + Ubuntu
    └── requires: admin PowerShell + reboot
        ├── gcc / g++ / make / cmake   (apt install build-essential)
        │       └── CPython from source (./configure; make; make altinstall)
        └── jq (also installable via winget on Windows-side — FASTER PATH)

jq (Windows-side)
    └── winget install stedolan.jq     ← NEXT ACTION (no reboot, no admin)
        └── doc.cmd.exe becomes fully operational
```

---

## Action Plan — Ordered by Unblocking Priority

| # | Action | Requires | Unlocks | Admin? |
|---|---|---|---|---|
| 1 | `winget install stedolan.jq` | winget ✓ | `doc.cmd.exe` fully operational | No |
| 2 | `wsl --install -d Ubuntu` | Admin PowerShell + reboot | Everything below | **Yes + reboot** |
| 3 | `sudo apt install build-essential` | WSL2 ✓ | gcc, g++, make | No (inside WSL) |
| 4 | `sudo apt install cmake ninja-build` | build-essential ✓ | cmake, ninja | No (inside WSL) |
| 5 | `sudo apt install jq` | WSL2 ✓ | jq inside Linux | No (inside WSL) |
| 6 | Build CPython from source | build-essential + deps ✓ | Real Python | No (inside WSL) |

---

## Memory Warning

Free RAM at audit time: **~843 MB**. This is dangerously low for compilation.

Before any `make` or `./configure` run:
```bash
# Check free RAM
powershell -Command "Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory"
# Target: > 2 GB free before starting a build
# Action if low: close Chrome tabs, other apps
```

---

## Next Immediate Action

```bash
# Step 1 — Install jq (no admin, no reboot, 30 seconds)
winget install stedolan.jq

# Verify
jq --version

# Step 2 — Test doc.cmd.exe
cd /c/Users/ACER/bitacora
doc.cmd.exe stats
doc.cmd.exe list
doc.cmd.exe search "python"
```

*After Step 1, the command database is fully operational.*
*After Step 2, WSL2 + the full build toolchain.*
