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
