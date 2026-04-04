#!/usr/bin/env bash
# env.sh — Project Environment Bootstrap
# ─────────────────────────────────────────────────────────────────────────────
# Source this file to load all tools, paths, and aliases for the Zr project.
#
#   source /c/Users/ACER/bitacora/env.sh
#   # or from anywhere inside the repo:
#   source "$(git rev-parse --show-toplevel)/env.sh"
#
# What it does:
#   - Adds bin/ (vendored binaries: jq) to PATH
#   - Adds tools/ (doc.*.exe scripts) to PATH
#   - Exports project variables (ZR_ROOT, ZR_LOG, ZR_DB, etc.)
#   - Defines short aliases (cmd, journal, log)
#   - Prints a status banner so you know it loaded
# ─────────────────────────────────────────────────────────────────────────────

# ── Locate repo root ──────────────────────────────────────────────────────────
if git rev-parse --show-toplevel &>/dev/null 2>&1; then
    ZR_ROOT="$(git rev-parse --show-toplevel)"
else
    ZR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
export ZR_ROOT

# ── Directories ───────────────────────────────────────────────────────────────
export ZR_BIN="$ZR_ROOT/bin"
export ZR_TOOLS="$ZR_ROOT/tools"
export ZR_LOGS="$ZR_ROOT/logs"
export ZR_JOURNAL="$ZR_ROOT/journal"
export ZR_PROCESS="$ZR_ROOT/process"

# ── PATH — prepend bin/ and tools/ ───────────────────────────────────────────
# Guards against duplicate entries on repeated sourcing
case ":$PATH:" in
    *":$ZR_BIN:"*)  ;;
    *) export PATH="$ZR_BIN:$PATH" ;;
esac
case ":$PATH:" in
    *":$ZR_TOOLS:"*)  ;;
    *) export PATH="$ZR_TOOLS:$PATH" ;;
esac

# ── Key file paths ────────────────────────────────────────────────────────────
export ZR_DB="$ZR_LOGS/log.commands.json"
export ZR_INSTALL="$ZR_LOGS/install.md"
export ZR_PROMPTS="$ZR_LOGS/prompts.md"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias zr='cd "$ZR_ROOT"'
alias cmd='doc.cmd.exe'
alias jrn='ls "$ZR_JOURNAL"'
alias cmds='doc.cmd.exe list'
alias hook='bash "$ZR_TOOLS/doc.git.hook-commit.exe"'
alias companion='powershell -ExecutionPolicy Bypass -File "$ZR_TOOLS/doc.companion.server.ps1" &'

# ── Banner ────────────────────────────────────────────────────────────────────
_ZR_GRN='\033[0;32m'; _ZR_CYN='\033[0;36m'; _ZR_DIM='\033[2m'; _ZR_RST='\033[0m'
_ZR_BLU='\033[0;34m'; _ZR_YLW='\033[0;33m'

echo -e ""
echo -e "  ${_ZR_CYN}Zr — Build From Source${_ZR_RST}  ${_ZR_DIM}environment loaded${_ZR_RST}"
echo -e "  ${_ZR_DIM}────────────────────────────────────────${_ZR_RST}"
echo -e "  ${_ZR_DIM}root    ${_ZR_RST} ${_ZR_BLU}$ZR_ROOT${_ZR_RST}"

# Tool availability checks
_zr_check() {
    local name="$1" cmd="$2"
    if "$cmd" --version &>/dev/null 2>&1 || command -v "$cmd" &>/dev/null; then
        local ver; ver="$("$cmd" --version 2>&1 | head -1 | tr -d "")"
        echo -e "  ${_ZR_GRN}✓${_ZR_RST} ${_ZR_DIM}${name}${_ZR_RST}      $ver"
    else
        echo -e "  ${_ZR_YLW}✗${_ZR_RST} ${_ZR_DIM}${name}${_ZR_RST}      not found"
    fi
}

_zr_check "git    " "git"
_zr_check "gh     " "gh"
_zr_check "jq     " "$ZR_BIN/jq.exe"
_zr_check "curl   " "curl"

# WSL check
if wsl -e uname -a &>/dev/null 2>&1; then
    echo -e "  ${_ZR_GRN}✓${_ZR_RST} ${_ZR_DIM}wsl    ${_ZR_RST}      $(wsl -e uname -sr 2>/dev/null)"
else
    echo -e "  ${_ZR_YLW}✗${_ZR_RST} ${_ZR_DIM}wsl    ${_ZR_RST}      no distro installed"
fi

echo -e "  ${_ZR_DIM}────────────────────────────────────────${_ZR_RST}"
echo -e "  ${_ZR_DIM}aliases${_ZR_RST}  zr · cmd · cmds · jrn · hook · companion"
echo -e ""

unset _ZR_GRN _ZR_CYN _ZR_DIM _ZR_RST _ZR_BLU _ZR_YLW
unset -f _zr_check
