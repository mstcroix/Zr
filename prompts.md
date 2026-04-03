# Prompts — Bitácora de Viaje

> Every prompt and response recorded here. Each commit = one answer.
> This file *is* the conversation history under version control.

---

## #001 — Bootstrap the development environment

**Date:** 2026-04-02
**Prompt:**
> Lets bootstrap our development environment. Check where we are which platform are we and lets start documenting (logging) in our "bitacora de viaje" our journey. You take care of bitacora.
> Lets start.
> Commonly any distro starts and finishes at GitHub... not really sure if this is the future... but lets start with common agreement on that. Check if we have git in this computer and create a new repo.
> The repo is about all we need to build our system from scratch/source-code, meaning we download, compile, install, execute, log all the steps from having windows 11 install ready, downloading git, cloning a repo, building from source code python until building our avant garde enterprise robust architecture atomic-apps.

**Thinking:**
- Need to identify OS, shell, hardware — run `uname`, `systeminfo`, `whoami`
- Check git presence and version
- Check GitHub CLI (`gh`) presence
- Establish where the bitácora lives on disk
- Architecture question: native Windows vs WSL2 — flag this as a decision point
- Create the journal structure (README + entries/) before doing anything else

**Answer:**

Environment discovered:

| Property | Value |
|---|---|
| OS | Windows 10 Home Single Language 22H2 (build 19045) |
| Shell | Git Bash (MINGW64 3.6.6) — not WSL |
| Architecture | x86_64 |
| CPUs | 4 logical |
| RAM | ~6 GB |
| Machine | DESKTOP-ICIQ279 |
| User | ACER |

**Git:** Installed — version 2.53.0.windows.2 at `/mingw64/bin/git`. No global user.name or user.email configured yet.

**GitHub CLI (`gh`):** Not installed.

**Actions taken:**
- Created `C:\Users\ACER\bitacora\` as the journal root
- Created `README.md` with project philosophy and chapter outline
- Created first entry: `entries/2026-04-02-day0-bootstrap.md`

**Open questions raised:**
- WSL2 vs native Windows as primary build environment?
- GitHub username, git name/email, repo name?

---

## #002 — Confirm WSL presence

**Date:** 2026-04-02
**Prompt:**
> Do we have WSL in this machine? Confirm this first. If yes, then WSL is preferred over native windows.

**Thinking:**
- Run `wsl --status`, `wsl --list --verbose`, `wsl -e uname -a`
- Output was garbled UTF-16 (Windows locale: Spanish) — decode pattern: spaced characters = UTF-16 rendered as Latin-1
- `wsl --list` returning the help/usage page (not a distro list) = definitive sign no distros are registered
- Check LXSS registry key as ground truth for installed distros
- Check `wsl.exe` and `wslapi.dll` exist in System32 — they do
- Windows ships `wsl.exe` as a stub since build 2004 even before WSL feature is enabled

**Answer:**

**WSL is NOT ready.** Partial state:

- `wsl.exe` and `wslapi.dll` present — Windows ships these as stubs
- No Linux distribution installed — `wsl --list` returns usage/help, LXSS registry key absent
- `wsl -e uname -a` fails — nothing to execute against

Decision recorded: **WSL2 preferred. Must install it first.**

Installing WSL2 + Ubuntu becomes **Chapter 1** of the bitácora.

Next steps (requires admin + reboot):
```
wsl --install -d Ubuntu
```

Still pending: GitHub username, git name/email, repo name.

---

## #007 — Create install.md bitacora

**Date:** 2026-04-02
**Prompt:**
> Create, mantain and keep under version control another bitacora named install.md with all the install commands and configuration commands you needed to prepare our environment setup.

**Thinking:**
- Companion file to prompts.md — focused purely on commands, not conversation
- Must be a reproducible recipe: someone with a fresh Windows 10 machine should be able to follow it top to bottom
- Include everything done so far: git (pre-installed), git config, git init, gh install via winget, PATH fix
- Mark pending steps clearly: gh auth (needs browser), repo create, push, WSL2, toolchain, CPython
- Keep it ordered, numbered, with verify commands after each step
- Same commit-per-update discipline as prompts.md

**Answer:**

Created `install.md` with 10 sections covering the full setup sequence:
- 001: Git (pre-installed, verify only)
- 002: `git config` identity
- 003: `git init` bitacora repo
- 004: `winget install --id GitHub.cli` → gh 2.89.0 ✓
- 005: `gh auth login` (PENDING — browser flow)
- 006: `gh repo create Zr` (PENDING)
- 007: `git remote add` + `git push` (PENDING)
- 008: `wsl --install -d Ubuntu` (PENDING — needs admin + reboot)
- 009: WSL2 toolchain — gcc, make, cmake (upcoming)
- 010: CPython from source (upcoming)

---

## #006 — Run gh install yourself

**Date:** 2026-04-02
**Prompt:**
> run it yourself

**Thinking:**
- Run `winget install --id GitHub.cli` directly via Bash tool
- Background the process, poll output file for completion
- winget downloaded `gh_2.89.0_windows_amd64.msi` (14 MB) from GitHub releases
- MSI installer ran silently — "Instalado correctamente"
- PATH not auto-updated in current shell — manually append `/c/Program Files/GitHub CLI`
- `gh --version` confirms: `gh version 2.89.0 (2026-03-26)`
- `gh auth login` requires interactive browser flow — cannot be automated, must be run by user

**Answer:**

`gh` 2.89.0 installed successfully via winget.

- Downloaded: `gh_2.89.0_windows_amd64.msi` (14 MB)
- Install path: `C:\Program Files\GitHub CLI\`
- Hash verified by winget before install

Next step requires user action — run in terminal:
```bash
gh auth login
```
Choose: GitHub.com → HTTPS → Login with web browser → authorize at github.com/login/device

---

## #005 — Install gh CLI before creating repo

**Date:** 2026-04-02
**Prompt:**
> B

**Thinking:**
- User chose to install `gh` CLI first — aligned with "document everything from source" philosophy
- Check what package managers are available: `winget` v1.28.220 present, scoop/choco absent
- `winget` is the cleanest choice: native to Windows 10, no extra tooling, leaves registry trail
- Write full Chapter 1 entry in bitácora before executing anything
- Walk the user through: install → verify → auth → create Zr → add remote → push
- After `winget install`, user must reopen terminal for PATH to update

**Answer:**

`winget` v1.28.220 is available — chosen as the install method.

Created `entries/2026-04-02-chapter1-gh-cli.md` with full step-by-step.

**Run this now** (Git Bash or PowerShell, no admin needed):

```bash
winget install --id GitHub.cli
```

Then reopen the terminal and come back.

---

## #004 — GitHub identity and repo name

**Date:** 2026-04-02
**Prompt:**
> mstcroix
> marco.santacruz@gmail.com
> repo-name: Zr

**Thinking:**
- Update local git config with real identity (was placeholder ACER/acer@localhost)
- `gh` CLI not installed — cannot create GitHub repo from CLI
- Options: (A) user creates repo manually at github.com/new then we add remote + push, or (B) install `gh` CLI first (more aligned with "document everything" philosophy)
- Repo name `Zr` — short, clean, intentional. Will live at github.com/mstcroix/Zr

**Answer:**

Git identity updated:
- `user.name` = Marco Santacruz
- `user.email` = marco.santacruz@gmail.com
- Scope: local (this repo only)

`gh` CLI not installed — cannot create remote repo programmatically yet.
Awaiting user choice: manual repo creation vs. installing `gh` CLI first.

Target remote: `https://github.com/mstcroix/Zr`

---

## #003 — Version-control the prompts

**Date:** 2026-04-02
**Prompt:**
> Create, mantain and keep under version management (using git) a file named prompts.md where you add each prompt and each of your answers and thinkin process. Each answer is a commit in git to the prompt.md file.

**Thinking:**
- Initialize git repo in the bitacora directory (natural home for this file)
- Need local git user.name and user.email — use `ACER` / `acer@localhost` as placeholder; user must update with real identity before pushing to GitHub
- Create prompts.md with full conversation history (prompts #001, #002, this one)
- Commit #001 and #002 as historical backfill with accurate dates
- Going forward: every answer appended here + one `git commit`
- Keep commits atomic: one prompt/answer pair per commit, message = prompt number + summary

**Answer:**

- Initialized git repo in `C:\Users\ACER\bitacora\` with local user config (`ACER` / `acer@localhost` — placeholder, update before pushing)
- Created this file: `prompts.md`
- Committed history backfill: #001 → `64bff30`, #002 → `65db8d2`
- This entry (#003) is its own commit
- From this point forward: every response = one commit to this file
- Git user is `ACER / acer@localhost` (local config only — update before pushing to GitHub)
- Commit message convention: `prompt #NNN — short summary of what was answered`
