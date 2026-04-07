#!/usr/bin/env bash
# env.sh — Project Environment Bootstrap
# ─────────────────────────────────────────────────────────────────────────────
# Source this file once per terminal session.
#
#   source /c/Users/ACER/bitacora/env.sh
#   source "$(git rev-parse --show-toplevel)/env.sh"
#
# Structure (UNIX-like):
#   bin/        ALL executables — scripts + compiled binaries
#   src/        source code (polyglot implementations)
#   dev/proc/   process definitions & rules
#   var/log/    append-only audit logs
#   mnt/journal/ dated narrative entries
# ─────────────────────────────────────────────────────────────────────────────

# ── Repo root ─────────────────────────────────────────────────────────────────
if git rev-parse --show-toplevel &>/dev/null 2>&1; then
    ZR_ROOT="$(git rev-parse --show-toplevel)"
else
    ZR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
export ZR_ROOT

# ── Directory exports ─────────────────────────────────────────────────────────
export ZR_BIN="$ZR_ROOT/bin"          # executables
export ZR_SRC="$ZR_ROOT/src"          # source code
export ZR_DEV="$ZR_ROOT/dev"          # process/config definitions
export ZR_PROC="$ZR_ROOT/dev/proc"    # process definitions
export ZR_LOG="$ZR_ROOT/var/log"      # audit logs
export ZR_JOURNAL="$ZR_ROOT/mnt/journal"  # narrative entries
export ZR_DB="$ZR_LOG/log.commands.json"

# ── PATH — prepend bin/ (guards against duplicates) ──────────────────────────
case ":$PATH:" in
    *":$ZR_BIN:"*) ;;
    *) export PATH="$ZR_BIN:$PATH" ;;
esac

# ── Aliases ───────────────────────────────────────────────────────────────────
alias zr='cd "$ZR_ROOT"'
alias cmd='doc.cmd.exe'
alias cmds='doc.cmd.exe list'
alias jrn='ls "$ZR_JOURNAL"'
alias lgs='ls "$ZR_LOG"'
alias hook='bash "$ZR_BIN/doc.git.hook-commit.exe"'
alias companion='powershell -ExecutionPolicy Bypass -File "$ZR_BIN/doc.companion.server.ps1" &'
alias proc='cat "$ZR_PROC/process.configuration-mgmnt.md" | head -60'

# ── Status banner ─────────────────────────────────────────────────────────────
_C='\033[0;36m'; _G='\033[0;32m'; _Y='\033[0;33m'
_B='\033[0;34m'; _D='\033[2m';    _Z='\033[0m'

_zr_tool() {
    local label="$1" bin="$2"
    if [[ -x "$bin" ]]; then
        local ver; ver="$("$bin" --version 2>&1 | head -1 | tr -d '\r')"
        printf "  ${_G}✓${_Z} ${_D}%-8s${_Z} %s\n" "$label" "$ver"
    elif command -v "$bin" &>/dev/null; then
        local ver; ver="$("$bin" --version 2>&1 | head -1 | tr -d '\r')"
        printf "  ${_G}✓${_Z} ${_D}%-8s${_Z} %s\n" "$label" "$ver"
    else
        printf "  ${_Y}✗${_Z} ${_D}%-8s${_Z} not found\n" "$label"
    fi
}

echo -e ""
echo -e "  ${_C}Zr${_Z} — build from source   ${_D}${ZR_ROOT}${_Z}"
echo -e "  ${_D}$(printf '─%.0s' {1..46})${_Z}"
_zr_tool "git"    "git"
_zr_tool "gh"     "gh"
_zr_tool "jq"     "$ZR_BIN/jq.exe"
_zr_tool "curl"   "curl"
wsl -e uname -sr &>/dev/null 2>&1 \
    && printf "  ${_G}✓${_Z} ${_D}%-8s${_Z} %s\n" "wsl" "$(wsl -e uname -sr 2>/dev/null)" \
    || printf "  ${_Y}✗${_Z} ${_D}%-8s${_Z} not installed\n" "wsl"
echo -e "  ${_D}$(printf '─%.0s' {1..46})${_Z}"
echo -e "  ${_D}bin/  src/  dev/proc/  var/log/  mnt/journal/${_Z}"
echo -e "  ${_D}cmd · cmds · jrn · lgs · hook · companion · proc${_Z}"
echo -e ""

unset _C _G _Y _B _D _Z
unset -f _zr_tool
