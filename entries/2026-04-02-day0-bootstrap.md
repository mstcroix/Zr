# Day 0 — Environment Recon & Repo Bootstrap
**Date:** 2026-04-02
**Status:** In progress

---

## System Snapshot

| Property | Value |
|---|---|
| OS | Windows 10 Home Single Language |
| OS Version | 10.0.19045 (build 19041.6456) |
| Machine name | DESKTOP-ICIQ279 |
| User | ACER |
| Shell | Git Bash (MINGW64 3.6.6) |
| Architecture | x86_64 |
| Logical CPUs | 4 |
| RAM | ~6 GB (6,361,997,312 bytes) |
| Home dir | C:\Users\ACER |

---

## What We Found

### Git
- **Status:** INSTALLED
- **Version:** git 2.53.0.windows.2
- **Path:** /mingw64/bin/git (Git for Windows / Git Bash)
- **User config:** NOT SET — needs `git config --global user.name` and `user.email`

### GitHub CLI (`gh`)
- **Status:** NOT INSTALLED
- **Next step:** Download from https://cli.github.com — will be documented in a future entry

### WSL2
- **Status:** PARTIAL — `wsl.exe` present (ships with Windows 10 2004+), but **no Linux distro installed**
- **Evidence:** `wsl --list` returns help/usage page (not a distro list); LXSS registry key absent; `wsl -e uname -a` fails
- **Next step:** Install WSL2 + Ubuntu — this is Chapter 1

### Python
- **Status:** Not yet checked
- **Plan:** Build from source (CPython) inside WSL2 — Chapter 3

### Compilers (gcc, clang, msvc)
- **Status:** Not yet checked
- **Plan:** gcc/clang/make inside WSL2 — Chapter 2

---

## Actions Taken

1. Confirmed Git Bash environment running on Windows 10
2. Created bitácora directory at `C:\Users\ACER\bitacora\`
3. Initialized journal structure (README + entries/)
4. [ ] Configure git global user.name and user.email
5. [ ] Initialize local git repo in bitácora directory
6. [ ] Create GitHub remote repo and push

---

## Notes

- The shell is MINGW64 (Git Bash), not WSL — no Linux kernel underneath.
  This matters when compiling from source: some tools need WSL or MSVC.
- Windows 10 build 19045 = 22H2 — the last major feature update for Win10.
  This machine won't get Windows 11 features natively.
- 6 GB RAM is workable but tight for heavy compilation jobs (LLVM, CPython with
  all extensions). We will note memory constraints per build step.

---

## Open Questions

- ~~Do we target WSL2 as the primary build environment or stay native Windows?~~ **DECIDED: WSL2 preferred. Must install it first.**
- GitHub account username? (needed for remote repo setup)
- Repo name? (suggested: `build-from-source` or `from-zero`)
