# process.languages.md — Polyglot Naming & Layout Conventions

> **Why this file exists:** When multiple languages coexist, naming chaos
> kills navigation. This document defines one law per language — enough
> to make every file findable without memorizing each ecosystem's defaults.

---

## Repository Layout (UNIX-inspired)

```
Zr/
├── bin/              ALL executables — scripts, compiled binaries, symlinks
│   ├── jq.exe        vendored binary (Windows)
│   ├── doc.cmd.exe   dispatcher → active implementation
│   └── doc.*.exe     other project tools
│
├── src/              source code only — nothing runs from here directly
│   └── doc.cmd/      one folder per tool, one subfolder per language
│       ├── bash/
│       ├── python/
│       ├── java/
│       ├── rust/
│       ├── zig/
│       ├── typescript/
│       ├── c/
│       └── cpp/
│
├── dev/              definitions of behavior (UNIX /dev analogy)
│   └── proc/         process definitions — how the project works
│
├── var/              variable data — grows over time
│   └── log/          append-only logs (UNIX /var/log)
│
├── mnt/              accumulated external-ish data (UNIX /mnt analogy)
│   └── journal/      dated narrative entries
│
├── env.sh            bootstrap: source once, get everything
└── README.md         auto-maintained index
```

### Rule: one place per concern

| Concern | Location | Why |
|---|---|---|
| "I want to run a tool" | `bin/` | All executables, one place |
| "I want to read the source" | `src/<tool>/<lang>/` | All source, one place |
| "I want to understand a rule" | `dev/proc/` | All process docs, one place |
| "I want to audit history" | `var/log/` | All logs, one place |
| "I want to read the story" | `mnt/journal/` | All entries, one place |

---

## Language Conventions

### How to read this table

- **File** = the main source file name in `src/doc.cmd/<lang>/`
- **Binary** = where the compiled output lands (relative to the language folder)
- **Symlink target** = what `bin/doc.cmd.exe` points to when this lang is active
- **Convention** = the naming rule for that language's ecosystem

---

| Lang | File | Binary out | Symlink target | Convention |
|---|---|---|---|---|
| **Bash** | `doc.cmd.sh` | *(interpreted)* | `src/doc.cmd/bash/doc.cmd.sh` | `kebab-case.sh` |
| **Python** | `doc_cmd.py` | *(interpreted)* | `src/doc.cmd/python/doc_cmd.py` | `snake_case.py` (PEP 8) |
| **Java** | `DocCmd.java` | `DocCmd.class` | via `java` launcher | `PascalCase.java` (class name = file name) |
| **Rust** | `src/main.rs` | `target/release/doc-cmd[.exe]` | `src/doc.cmd/rust/target/release/doc-cmd.exe` | `snake_case.rs`, project name `kebab-case` in Cargo.toml |
| **Zig** | `src/main.zig` | `zig-out/bin/doc-cmd[.exe]` | `src/doc.cmd/zig/zig-out/bin/doc-cmd.exe` | `snake_case.zig`, project name in `build.zig` |
| **TypeScript** | `src/index.ts` | `dist/index.js` | via `node dist/index.js` | `camelCase.ts`, entry = `index.ts`, project = `kebab-case` in `package.json` |
| **C** | `doc_cmd.c` | `doc_cmd[.exe]` | `src/doc.cmd/c/doc_cmd.exe` | `snake_case.c`, Makefile in same dir |
| **C++** | `doc_cmd.cpp` | `doc_cmd[.exe]` | `src/doc.cmd/cpp/doc_cmd.exe` | `snake_case.cpp`, Makefile in same dir |

---

## Build Commands

```bash
# ── Rust ──────────────────────────────────────────────────────
cd src/doc.cmd/rust
cargo build --release
# output: target/release/doc-cmd.exe (Windows) / doc-cmd (Linux)

# ── Zig ───────────────────────────────────────────────────────
cd src/doc.cmd/zig
zig build -Doptimize=ReleaseFast
# output: zig-out/bin/doc-cmd.exe / doc-cmd

# ── TypeScript ────────────────────────────────────────────────
cd src/doc.cmd/typescript
npm install && npm run build
# output: dist/index.js

# ── Java ──────────────────────────────────────────────────────
cd src/doc.cmd/java
javac DocCmd.java
# output: DocCmd.class (run with: java DocCmd)

# ── C ─────────────────────────────────────────────────────────
cd src/doc.cmd/c
make
# output: doc_cmd.exe / doc_cmd

# ── C++ ───────────────────────────────────────────────────────
cd src/doc.cmd/cpp
make
# output: doc_cmd.exe / doc_cmd

# ── Python / Bash ─────────────────────────────────────────────
# No build step. Run directly.
```

---

## Dispatcher Priority

`bin/doc.cmd.exe` is a Bash dispatcher. It tries each implementation
in order and runs the first available. Priority:

```
1. Rust    (fastest — compiled native binary)
2. Zig     (fast — compiled native binary)
3. C       (fast — compiled native binary)
4. C++     (fast — compiled native binary)
5. Python  (interpreted — if python3 available)
6. Java    (interpreted — if java + DocCmd.class available)
7. Node.js (interpreted — if node + dist/index.js available)
8. Bash    (always available — guaranteed fallback)
```

---

## The `bin/doc.cmd.exe` File

On Windows (Git Bash): `bin/doc.cmd.exe` is the **dispatcher Bash script**.
When a compiled binary is available, it `exec`s into it — zero overhead.

On Linux/WSL (future): same dispatcher, same priority list, `.exe` suffix
stripped for non-Windows targets automatically.

> **Rule:** `bin/doc.cmd.exe` is always the user-facing entry point.
> Never call language implementations directly.

---

## Naming Laws (immutable)

| Law | Rule | Why |
|---|---|---|
| No spaces in filenames | Always | Breaks shell quoting everywhere |
| Language folder = language name | `bash/`, `python/`, `rust/` etc. | Self-documenting, predictable |
| Source file follows language convention | See table above | Respects each ecosystem's tooling expectations |
| Binary output stays inside language folder | `rust/target/`, `zig/zig-out/` | Never pollute `src/` root |
| `bin/` only contains runnable files | No .md, no .json | One purpose per directory |
| `bin/doc.cmd.exe` is always the dispatcher | Never hardcode a language | Allows hot-swapping implementations |

---

*Last updated: 2026-04-02*
