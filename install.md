# install.md — Environment Setup Commands
> Every install and configuration command, in order, with context.
> Each update to this file is a commit. This is the reproducible recipe.

---

## Machine baseline
- **OS:** Windows 10 Home Single Language 22H2 (build 19045)
- **Shell:** Git Bash (MINGW64 3.6.6) — primary shell for all commands below
- **User:** ACER (`C:\Users\ACER`)
- **Date started:** 2026-04-02

---

## 001 — Git (already installed)

**Status:** Pre-installed (Git for Windows)
**Version:** 2.53.0.windows.2
**Path:** `/mingw64/bin/git`
**No install command needed.** Git for Windows was already present on the machine.

Verify:
```bash
git --version
# git version 2.53.0.windows.2
```

---

## 002 — Git global identity

```bash
# Run inside C:\Users\ACER\bitacora (local scope)
git config user.name "Marco Santacruz"
git config user.email "marco.santacruz@gmail.com"
```

**Scope:** local (repo-level, not `--global`)
**Why local:** global config was not set; using local keeps it explicit per-repo.

Verify:
```bash
git config user.name
# Marco Santacruz
git config user.email
# marco.santacruz@gmail.com
```

---

## 003 — Initialize bitacora git repo

```bash
mkdir -p /c/Users/ACER/bitacora
cd /c/Users/ACER/bitacora
git init
```

**Result:** Empty repo initialized at `C:\Users\ACER\bitacora\.git`

---

## 004 — GitHub CLI (`gh`)

**Installed via:** `winget` (v1.28.220 — pre-installed on this machine)
**Version installed:** 2.89.0
**Installer:** `gh_2.89.0_windows_amd64.msi` (14 MB)
**Install path:** `C:\Program Files\GitHub CLI\`

```bash
winget install --id GitHub.cli
```

**Note:** After install, PATH is not updated in the current shell session.
Add manually for the current session:

```bash
export PATH=$PATH:"/c/Program Files/GitHub CLI"
```

For permanent effect, close and reopen Git Bash (Windows will have updated the system PATH).

Verify:
```bash
gh --version
# gh version 2.89.0 (2026-03-26)
```

---

## 005 — GitHub CLI authentication

**Status:** DONE — 2026-04-02

```bash
gh auth login -h github.com -p https -w
# One-time code: 5F19-F033
# URL: https://github.com/login/device
# → user entered code in browser → Authorized
```

Result:
```
✓ Authentication complete.
✓ Configured git protocol
✓ Logged in as mstcroix
```

Verify:
```bash
gh auth status
# ✓ Logged in to github.com account mstcroix (keyring)
# Token scopes: 'gist', 'read:org', 'repo'
```

---

## 006 — Create GitHub repo Zr

**Status:** DONE — 2026-04-02

```bash
gh repo create Zr --public --description "Build from source: Windows → WSL2 → Python → enterprise atomic apps"
# https://github.com/mstcroix/Zr
```

---

## 007 — Push local bitacora to GitHub

**Status:** DONE — 2026-04-02

```bash
cd /c/Users/ACER/bitacora
git remote add origin https://github.com/mstcroix/Zr.git
git push -u origin master
# * [new branch] master -> master
# branch 'master' set up to track 'origin/master'
```

Verify:
```bash
git remote -v
# origin  https://github.com/mstcroix/Zr.git (fetch)
# origin  https://github.com/mstcroix/Zr.git (push)
```

---

## 008 — WSL2 + Ubuntu

**Status:** PENDING — `wsl.exe` is present but no distro installed

Open **PowerShell as Administrator** and run:

```powershell
wsl --install -d Ubuntu
```

This command:
- Enables the "Windows Subsystem for Linux" optional feature
- Enables the "Virtual Machine Platform" optional feature
- Downloads and installs the WSL2 Linux kernel
- Downloads and installs Ubuntu from the Microsoft Store
- **Requires a reboot**

After reboot, Ubuntu launches automatically and prompts:
```
Enter new UNIX username:
New password:
```

Verify (after reboot and first-run setup):
```bash
wsl -e uname -a
# Linux ... x86_64 GNU/Linux

wsl -e lsb_release -a
# Ubuntu ...
```

---

## 009 — (Upcoming) Toolchain inside WSL2

> To be documented after WSL2 is running.

```bash
wsl
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential gcc g++ make cmake git curl wget
gcc --version
```

---

## 010 — (Upcoming) Python from source inside WSL2

> To be documented after toolchain (#009) is ready.

```bash
# Inside WSL2
sudo apt install -y \
  libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
  libffi-dev zlib1g-dev liblzma-dev libncurses5-dev

git clone https://github.com/python/cpython.git
cd cpython
git checkout v3.13.0  # or latest stable
./configure --enable-optimizations
make -j$(nproc)
sudo make altinstall
python3.13 --version
```

---

*Last updated: 2026-04-02 | Pending: #008 WSL2, #009 toolchain, #010 CPython from source*
