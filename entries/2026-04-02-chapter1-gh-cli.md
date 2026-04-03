# Chapter 1 — GitHub CLI (`gh`)
**Date:** 2026-04-02
**Status:** In progress

---

## Goal

Install `gh` CLI so we can create and manage GitHub repos from the terminal,
authenticate to GitHub, create `Zr`, and push our local bitácora history.

---

## What is `gh`?

GitHub's official CLI. Lets you do everything github.com can do — create repos,
open PRs, manage issues, authenticate — without leaving the terminal.
Source: https://github.com/cli/cli

---

## Package Manager Decision

| Manager | Available | Notes |
|---|---|---|
| `winget` | YES — v1.28.220 | Ships with Windows 10 since 2021. Native. No install needed. |
| `scoop` | NO | |
| `choco` | NO | |

**Decision: use `winget`.** It's already present, it's Microsoft's own tool, and
it leaves a clean audit trail in Windows' software registry.

---

## Installation Steps

### Step 1 — Install via winget

Open a **regular terminal** (Git Bash or PowerShell — no admin needed for winget):

```bash
winget install --id GitHub.cli
```

Expected output:
```
Found GitHub CLI [GitHub.cli]
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it license, third-party packages.
Downloading https://github.com/cli/cli/releases/download/...
Successfully installed
```

### Step 2 — Verify installation

```bash
gh --version
```

Expected: `gh version X.Y.Z (YYYY-MM-DD)`

### Step 3 — Authenticate to GitHub

```bash
gh auth login
```

Interactive prompts — choose:
- `GitHub.com`
- `HTTPS`
- Authenticate with a web browser (opens github.com, paste the one-time code)

### Step 4 — Verify auth

```bash
gh auth status
```

Expected: `Logged in to github.com as mstcroix`

### Step 5 — Create repo Zr

```bash
gh repo create Zr --public --description "Build from source: Windows → WSL2 → Python → enterprise atomic apps" --confirm
```

### Step 6 — Add remote and push

```bash
cd /c/Users/ACER/bitacora
git remote add origin https://github.com/mstcroix/Zr.git
git push -u origin master
```

---

## Observed Results

| Step | Status | Notes |
|---|---|---|
| winget available | CONFIRMED — v1.28.220 | |
| `winget install GitHub.cli` | pending | |
| `gh --version` | pending | |
| `gh auth login` | pending | |
| `gh repo create Zr` | pending | |
| `git push -u origin master` | pending | |

---

## Notes

- `winget` installs to `C:\Users\ACER\AppData\Local\Microsoft\WinGet\...` by default
- After install, **close and reopen the terminal** so the new `gh` binary is in PATH
- The `gh auth login` browser flow requires the GitHub account `mstcroix` to be
  logged in at github.com in your browser before running the command
