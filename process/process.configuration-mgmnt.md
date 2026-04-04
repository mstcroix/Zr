# process.configuration-mgmnt.md
# Configuration Management Process

> **Why this file exists:** Every system accumulates decisions. Without a
> document that captures *why* each decision was made and *what it serves*,
> the system becomes archaeology — you dig through files and commits trying
> to reconstruct intent. This file makes intent explicit, auditable, and
> evolvable.
>
> **What it is for:** To define the rules, structures, and conventions of
> this repository so that any person (or AI) joining at any point can
> understand not just *what* exists, but *why* it exists and *what would
> break* if it were changed.

---

## 1. Repository Identity

| Property | Value | Why |
|---|---|---|
| Name | `Zr` | Short, intentional. Zero → Run. The journey from nothing to running systems. |
| Remote | `https://github.com/mstcroix/Zr` | GitHub as canonical remote. Chosen because it is the industry default starting point. |
| Owner | `mstcroix` (Marco Santacruz) | Single owner during bootstrap phase. |
| Branch | `master` | Default branch. Not renamed — keeping it explicit as a convention choice, not an oversight. |
| Visibility | Public | This is a learning and documentation journey. Public keeps it honest. |
| Local path | `C:\Users\ACER\bitacora\` | `bitacora` = logbook in Spanish. The repo *is* the logbook. |

---

## 2. File Taxonomy — Prefixes and Purposes

Every file in this repository belongs to a type. Type is signaled by its
**filename prefix** or **location**. No file exists without a declared purpose.

### 2.1 Prefix System

| Prefix | Type | Purpose | Why it exists |
|---|---|---|---|
| *(none)* | Index / Standard | Root-level standard files (`README.md`) | Convention. README is the universal entry point. |
| `process.` | Process definition | Defines *how* the team/project works — rules, conventions, workflows | Separates "what we built" from "how we work". Auditable. |
| `doc.` | Executable documentation | Files that are both documentation AND runnable scripts | Documents its own behavior inline. Dual-purpose: read it, run it. |
| `log.` | Append-only logs | Chronological records of actions taken | Pure history. Never edited retroactively. |
| `entries/` | Dated journal entries | Narrative accounts of work done, decisions made, obstacles hit | The human-readable story behind the commits. |

### 2.2 Legacy Names (pre-convention)

These files were created before the prefix convention was defined. They are
not renamed to preserve git history integrity.

| File | Effective type | Would be named today |
|---|---|---|
| `install.md` | Log | `log.install.md` |
| `prompts.md` | Log | `log.prompts.md` |

> **Rule:** Do not rename files retroactively. Git history is truth.
> Note the legacy name here instead. If renamed in the future, record the
> decision in this file with a date and reason.

---

## 3. File Structure

```
Zr/
│
├── README.md                          ← Auto-maintained index. DO NOT edit manually.
│                                         Managed by: doc.git.hook-commit.exe
│                                         Why: single entry point, always current.
│
├── process.configuration-mgmnt.md    ← THIS FILE. Configuration management rules.
│                                         Why: makes every convention explicit + auditable.
│
├── doc.git.hook-commit.exe            ← Pre-commit hook logic (bash script).
│                                         Why: automation lives in the repo, not hidden in .git/.
│                                         Called by: .git/hooks/pre-commit
│
├── install.md                         ← Ordered log of every install + config command.
│   (→ log.install.md)                    Why: reproducibility. A new machine follows this file.
│                                         Rule: append-only. Mark steps DONE, never delete.
│
├── prompts.md                         ← Full conversation log: every prompt + answer + thinking.
│   (→ log.prompts.md)                    Why: the AI-human dialogue is part of the audit trail.
│                                         Rule: one entry per prompt. One commit per answer.
│
├── entries/                           ← Dated narrative journal entries.
│   │                                     Why: human-readable context behind commits.
│   │                                     Rule: filename must start with YYYY-MM-DD-.
│   │
│   ├── 2026-04-02-day0-bootstrap.md   ← Environment recon. Day zero.
│   └── 2026-04-02-chapter1-gh-cli.md  ← Chapter 1: installing gh CLI.
│
└── .git/
    └── hooks/
        └── pre-commit                 ← Thin delegator. Calls doc.git.hook-commit.exe.
                                          Why: keeps hook logic version-controlled, not buried here.
```

---

## 4. Naming Conventions

### 4.1 Rules

| Convention | Rule | Why |
|---|---|---|
| Case | `kebab-case` for all filenames | Portable. Works on Linux (WSL2), Windows, macOS without case-collision issues. |
| Separators | `-` between words, `.` between prefix and name | `.` signals type boundary. `-` signals word boundary within name. |
| Dates | `YYYY-MM-DD` prefix for entries/ files | ISO 8601. Sorts chronologically without special tooling. |
| Extensions | `.md` for all human-readable docs, `.exe` for executable scripts | `.md` = readable in GitHub, editors, anywhere. `.exe` suffix signals "this runs" even if it is a bash script. |
| Abbreviations | Allowed only if unambiguous in context | `mgmnt` = management (this file). `gh` = GitHub CLI (universal). Never abbreviate proper nouns. |

### 4.2 What a filename must answer

Every filename must answer three questions:
1. **What type is this?** → signaled by prefix or location
2. **What is it about?** → signaled by the slug
3. **Is it time-ordered?** → if yes, starts with `YYYY-MM-DD`

---

## 5. Git Commit Standards

### 5.1 Commit message format

```
<scope> #NNN — <short imperative summary>
```

| Part | Rule | Why |
|---|---|---|
| `scope` | `prompt` for AI-driven commits, `fix` / `add` / `update` for manual | Makes origin of commit readable at a glance in `git log`. |
| `#NNN` | Sequential number matching prompts.md entry | Links commit directly to the conversation that produced it. |
| `—` | Em dash separator | Visual clarity in log output. |
| Summary | Imperative, ≤ 72 chars, no period | Git convention. Reads as: "This commit will: ___". |

### 5.2 When to commit

| Trigger | Rule |
|---|---|
| Every AI answer | One commit per prompt/answer pair. Logged in prompts.md. |
| New entry file | Commit the entry file. Hook updates README.md automatically. |
| Process change | Any change to a `process.` file gets its own commit — never bundled. |
| Install step completed | Update install.md, commit. Marks the step as done in history. |

### 5.3 What a commit must contain

Every commit must be self-describing. Reading `git log --oneline` should
tell the full story of the project without opening any file.

> **Rule:** If you cannot describe a commit in one line, it contains too
> many things. Split it.

### 5.4 Atomic commits

One concern per commit. Never bundle:
- A process change + a log update
- A new entry + an install step
- A fix + a feature

**Why:** Atomic commits make `git bisect`, `git revert`, and code review
meaningful. A bundled commit cannot be partially reverted.

---

## 6. Hook System

### 6.1 Architecture

```
commit triggered
      │
      ▼
.git/hooks/pre-commit          (untracked, thin delegator)
      │
      ▼
doc.git.hook-commit.exe        (tracked, version-controlled logic)
      │
      ├── scan entries/*.md
      ├── sort by git commit order
      ├── extract date + title per file
      ├── rebuild README.md § Journal Entries via awk
      └── git add README.md  (only if changed)
```

### 6.2 Rules for hooks

| Rule | Why |
|---|---|
| Hook logic lives in the repo, not in `.git/` | `.git/` is not tracked. Logic in `.git/` is invisible to history and dies on clone. |
| `.git/hooks/pre-commit` is always a thin delegator | One line: `exec "$REPO_ROOT/doc.git.hook-commit.exe"`. Never put logic here. |
| Hooks must `exit 0` | A hook that exits non-zero blocks all commits. Never let automation block work. |
| Hooks must be idempotent | Running the hook twice must produce the same result as running it once. |
| New hooks follow `doc.<trigger>-<action>.exe` naming | e.g. `doc.git.hook-push.exe` for a pre-push hook. |

---

## 7. Audit Trail

### 7.1 How to audit a decision

Every decision in this repo is traceable through three layers:

```
git log --oneline          → what changed, when, in what order
prompts.md                 → why it changed (the conversation + thinking)
process.*.md               → what rules govern it
```

### 7.2 How to audit a file

For any file `F`:
```bash
git log --follow --oneline -- F        # full history of F
git show <commit> -- F                 # F at a specific point in time
git diff <commit-a> <commit-b> -- F    # what changed between two points
```

### 7.3 How to audit the environment

```bash
cat install.md             # every command run, in order, with status
git log --oneline          # every state change, in order
```

### 7.4 Auditability rules

| Rule | Why |
|---|---|
| Never force-push to master | Rewrites history. Destroys audit trail. |
| Never amend published commits | Same reason. |
| Never delete files from history | Use "DEPRECATED" markers instead. |
| prompts.md is append-only | It is a log. Logs do not get edited. |
| install.md steps are marked DONE, never deleted | A deleted step hides what was actually run. |

---

## 8. Decision Log

Significant decisions recorded here with date and rationale.
Append-only. Do not edit past entries.

---

### 2026-04-02 — WSL2 as primary build environment

**Decision:** Use WSL2 (Linux) over native Windows (Git Bash / MSVC) for all
compilation and toolchain work.

**Why:** Native Windows toolchains (MSVC, MinGW) have friction with
open-source build systems. WSL2 gives a real Linux kernel — `./configure`,
`make`, `gcc` all work as documented upstream. No translation layer surprises.

**What it affects:** All entries from Chapter 2 onward. CPython, toolchain,
Docker — everything builds inside WSL2.

**Status:** WSL2 not yet installed. Pending admin + reboot.

---

### 2026-04-02 — winget as Windows package manager

**Decision:** Use `winget` (v1.28.220, pre-installed) over scoop or choco for
Windows-side package installs.

**Why:** Native to Windows 10/11. No third-party install required. Leaves a
clean audit trail in the Windows software registry. Hash-verified downloads.

**What it affects:** All Windows-side installs (gh CLI installed this way).

---

### 2026-04-02 — GitHub as remote (not GitLab, Gitea, etc.)

**Decision:** GitHub (`github.com/mstcroix/Zr`) as the canonical remote.

**Why:** Industry default. Best tooling ecosystem (`gh` CLI, Actions, Pages).
Acknowledged as "common agreement on that" in prompt #001, with the note that
this may not be the future — but it is the pragmatic start.

---

### 2026-04-02 — Prefix-based file taxonomy

**Decision:** Files are typed by prefix (`process.`, `doc.`, `log.`) rather
than by folder or extension alone.

**Why:** Folders create hierarchy but hide type at a glance. Prefixes make
type visible in any file listing, any grep, any `git log`. Flat repo root with
typed names is more scannable than nested folders for a small project.

---

*Last updated: 2026-04-02 | This document is governed by itself.*
