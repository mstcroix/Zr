#!/usr/bin/env bash
# tools/doc.cmd.exe — Command Database: lookup, record, replay
# ─────────────────────────────────────────────────────────────────────────────
# Every command run in this project passes through here.
# Prevents redundant re-runs. Builds an auditable, searchable history.
#
# Usage:
#   tools/doc.cmd.exe run    "git --version"   # run + record (prompts if known)
#   tools/doc.cmd.exe check  "git --version"   # lookup only, no run
#   tools/doc.cmd.exe list                      # list all recorded commands
#   tools/doc.cmd.exe search "python"           # search by keyword or tag
#   tools/doc.cmd.exe show   "git --version"   # show full JSON entry
#   tools/doc.cmd.exe stats                     # summary statistics
#
# Deps: bin/jq.exe (vendored — no system install needed)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
DB="$REPO_ROOT/var/log/log.commands.json"
JQ="$REPO_ROOT/bin/jq.exe"
TODAY="$(date +%Y-%m-%d)"

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[0;33m'
BLU='\033[0;34m'; CYN='\033[0;36m'; DIM='\033[2m'; RST='\033[0m'

die()  { echo -e "${RED}✗ $*${RST}" >&2; exit 1; }
info() { echo -e "${CYN}ℹ $*${RST}"; }
ok()   { echo -e "${GRN}✓ $*${RST}"; }
warn() { echo -e "${YLW}⚠ $*${RST}"; }

require_jq() { [[ -x "$JQ" ]] || die "bin/jq.exe not found — repo may be incomplete"; }
normalize()  { echo "$*" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

db_exists() {
  require_jq; local key; key="$(normalize "$1")"
  "$JQ" -e --arg k "$key" '.commands[$k] != null' "$DB" &>/dev/null
}
db_get() { require_jq; "$JQ" -r --arg k "$1" --arg f "$2" '.commands[$k][$f] // "—"' "$DB"; }

db_bump() {
  require_jq; local key; key="$(normalize "$1")"; local output="${2:-}"; local tmp; tmp="$(mktemp)"
  "$JQ" --arg k "$key" --arg d "$TODAY" --arg o "$output" '
    .commands[$k].count += 1 | .commands[$k].last_run = $d |
    if $o != "" then .commands[$k].last_output = $o else . end | .updated = $d
  ' "$DB" > "$tmp" && mv "$tmp" "$DB"
}

db_add() {
  require_jq; local key; key="$(normalize "$1")"
  local output="${2:-}" purpose="${3:-}" tags="${4:-[]}"; local tmp; tmp="$(mktemp)"
  "$JQ" --arg k "$key" --arg d "$TODAY" --arg o "$output" --arg p "$purpose" --argjson t "$tags" '
    .commands[$k] = {cmd:$k,purpose:$p,tags:$t,count:1,first_run:$d,last_run:$d,last_output:$o} | .updated=$d
  ' "$DB" > "$tmp" && mv "$tmp" "$DB"
}

cmd_run() {
  require_jq; local key; key="$(normalize "$*")"
  if db_exists "$key"; then
    warn "KNOWN ($(db_get "$key" count)×, last: $(db_get "$key" last_run))"
    echo -e "  ${DIM}Cached output:${RST} $(db_get "$key" last_output)"
    read -r -p "  Re-run anyway? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
      db_bump "$key"; info "Skipped — using cached."; echo "$(db_get "$key" last_output)"; return 0
    fi
  fi
  info "Running: ${BLU}${key}${RST}"
  local output; output="$(eval "$key" 2>&1)" || true; echo "$output"
  if db_exists "$key"; then db_bump "$key" "$output"; ok "Counter: $(db_get "$key" count) runs"
  else db_add "$key" "$output" "" '["new"]'; ok "Recorded in var/log/log.commands.json"; fi
}

cmd_check() {
  require_jq; local key; key="$(normalize "$*")"
  if db_exists "$key"; then
    echo -e "\n${GRN}● FOUND${RST}  ${BLU}${key}${RST}"
    echo -e "  purpose : $(db_get "$key" purpose)"
    echo -e "  tags    : $("$JQ" -r --arg k "$key" '.commands[$k].tags|join(", ")' "$DB")"
    echo -e "  runs    : $(db_get "$key" count) (last: $(db_get "$key" last_run))"
    echo -e "  output  : $(db_get "$key" last_output)\n"
  else
    warn "NOT in database: ${key}"
    echo -e "  Add it: tools/doc.cmd.exe run \"${key}\"\n"
  fi
}

cmd_list() {
  require_jq
  echo -e "\n${CYN}Command DB — $("$JQ" '.commands|length' "$DB") entries${RST}\n"
  printf "  %-3s  %-54s  %-12s  %s\n" "#" "COMMAND" "LAST RUN" "RUNS"
  printf "  %-3s  %-54s  %-12s  %s\n" "───" "──────────────────────────────────────────────────────" "────────────" "────"
  local i=1
  "$JQ" -r '.commands|to_entries[]|"\(.value.count) \(.value.last_run) \(.key)"' "$DB" \
    | sort -rn | while IFS=' ' read -r count last cmd; do
      printf "  %-3s  %-54s  %-12s  %s\n" "$i" "${cmd:0:54}" "$last" "${count}×"
      ((i++)) || true
    done; echo ""
}

cmd_search() {
  require_jq; local kw="$*"
  echo -e "\n${CYN}Search: \"${kw}\"${RST}\n"
  "$JQ" -r --arg kw "$kw" '
    .commands|to_entries[]
    |select((.key|ascii_downcase|contains($kw|ascii_downcase)) or
            (.value.purpose|ascii_downcase|contains($kw|ascii_downcase)) or
            (.value.tags[]?|ascii_downcase|contains($kw|ascii_downcase)))
    |"  [\(.value.count)×]  \(.key)\n         └─ \(.value.purpose)"
  ' "$DB"; echo ""
}

cmd_show() {
  require_jq; local key; key="$(normalize "$*")"
  if db_exists "$key"; then "$JQ" --arg k "$key" '.commands[$k]' "$DB"
  else warn "Not found: $key"; fi
}

cmd_stats() {
  require_jq
  echo -e "\n${CYN}Command DB Stats${RST}"
  echo -e "  Total runs  : ${GRN}$("$JQ" '[.commands[].count]|add' "$DB")${RST}"
  echo -e "  Unique cmds : ${GRN}$("$JQ" '.commands|length' "$DB")${RST}"
  echo -e "  Most run    : ${BLU}$("$JQ" -r '[.commands|to_entries[]|{k:.key,c:.value.count}]|sort_by(-.c)|.[0]|"\(.c)× \(.k)"' "$DB")${RST}\n"
}

ACTION="${1:-list}"; shift 2>/dev/null || true
case "$ACTION" in
  run)    cmd_run    "$@" ;;
  check)  cmd_check  "$@" ;;
  list)   cmd_list        ;;
  search) cmd_search "$@" ;;
  show)   cmd_show   "$@" ;;
  stats)  cmd_stats       ;;
  *)      echo "Usage: tools/doc.cmd.exe [run|check|list|search|show|stats] [cmd]"; exit 1 ;;
esac
