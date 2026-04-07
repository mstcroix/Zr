#!/usr/bin/env python3
"""
doc_cmd.py — Command Database (Python implementation)
Native JSON via stdlib. No external dependencies.
Language choice: Python — available on all platforms, stdlib json is robust,
readable syntax makes the logic self-documenting.
"""
import json, sys, os, subprocess, datetime
from pathlib import Path

# ── Locate repo root ──────────────────────────────────────────────────────────
def repo_root() -> Path:
    try:
        r = subprocess.run(["git","rev-parse","--show-toplevel"],
                           capture_output=True, text=True, check=True)
        return Path(r.stdout.strip())
    except Exception:
        return Path(__file__).parent.parent.parent.parent

ROOT   = repo_root()
DB     = ROOT / "var" / "log" / "log.commands.json"
TODAY  = datetime.date.today().isoformat()

# ── Colors ────────────────────────────────────────────────────────────────────
R="\033[0;31m"; G="\033[0;32m"; Y="\033[0;33m"
B="\033[0;34m"; C="\033[0;36m"; D="\033[2m";  Z="\033[0m"

def die(msg):  print(f"{R}✗ {msg}{Z}", file=sys.stderr); sys.exit(1)
def info(msg): print(f"{C}ℹ {msg}{Z}")
def ok(msg):   print(f"{G}✓ {msg}{Z}")
def warn(msg): print(f"{Y}⚠ {msg}{Z}")

# ── DB helpers ────────────────────────────────────────────────────────────────
def load() -> dict:
    if not DB.exists(): die(f"DB not found: {DB}")
    return json.loads(DB.read_text(encoding="utf-8"))

def save(data: dict):
    data["updated"] = TODAY
    DB.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

def normalize(cmd: str) -> str: return cmd.strip()

# ── Commands ──────────────────────────────────────────────────────────────────
def cmd_list():
    data = load(); cmds = data["commands"]
    print(f"\n{C}Command DB — {B}{len(cmds)}{C} entries{Z}\n")
    fmt = "  {:<3}  {:<54}  {:<12}  {}"
    print(fmt.format("#","COMMAND","LAST RUN","RUNS"))
    print(fmt.format("───","─"*54,"────────────","────"))
    for i,(k,v) in enumerate(sorted(cmds.items(),key=lambda x:-x[1]["count"]),1):
        print(fmt.format(i, k[:54], v["last_run"], f"{v['count']}×"))
    print()

def cmd_check(key: str):
    key = normalize(key); data = load(); cmds = data["commands"]
    if key in cmds:
        v = cmds[key]
        print(f"\n{G}● FOUND{Z}  {B}{key}{Z}")
        print(f"  purpose : {v.get('purpose','—')}")
        print(f"  tags    : {', '.join(v.get('tags',[]))}")
        print(f"  runs    : {v['count']} (last: {v['last_run']})")
        print(f"  output  : {v.get('last_output','—')}\n")
    else:
        warn(f"NOT in database: {key}")
        print(f"  Add it: doc_cmd.py run \"{key}\"\n")

def cmd_run(key: str):
    key = normalize(key); data = load(); cmds = data["commands"]
    if key in cmds:
        v = cmds[key]
        warn(f"KNOWN ({v['count']}×, last: {v['last_run']})")
        print(f"  {D}Cached:{Z} {v.get('last_output','—')}")
        ans = input("  Re-run anyway? [y/N] ")
        if ans.lower() != "y":
            v["count"] += 1; v["last_run"] = TODAY; save(data)
            info("Skipped — using cached."); print(v.get("last_output","")); return
    info(f"Running: {B}{key}{Z}")
    result = subprocess.run(key, shell=True, capture_output=True, text=True)
    output = (result.stdout + result.stderr).strip()
    print(output)
    if key in cmds:
        cmds[key]["count"] += 1; cmds[key]["last_run"] = TODAY
        cmds[key]["last_output"] = output[:500]
        ok(f"Counter: {cmds[key]['count']} runs")
    else:
        cmds[key] = {"cmd":key,"purpose":"","tags":["new"],"count":1,
                     "first_run":TODAY,"last_run":TODAY,"last_output":output[:500]}
        ok("Recorded in var/log/log.commands.json")
    save(data)

def cmd_search(kw: str):
    kw = kw.lower(); data = load()
    print(f"\n{C}Search: \"{kw}\"{Z}\n")
    for k,v in data["commands"].items():
        if (kw in k.lower() or kw in v.get("purpose","").lower()
                or any(kw in t.lower() for t in v.get("tags",[]))):
            print(f"  [{v['count']}×]  {k}\n         └─ {v.get('purpose','—')}")
    print()

def cmd_show(key: str):
    key = normalize(key); data = load()
    if key in data["commands"]:
        print(json.dumps(data["commands"][key], indent=2))
    else:
        warn(f"Not found: {key}")

def cmd_stats():
    data = load(); cmds = data["commands"]
    total = sum(v["count"] for v in cmds.values())
    top   = max(cmds.items(), key=lambda x:x[1]["count"])
    print(f"\n{C}Command DB Stats{Z}")
    print(f"  Total runs  : {G}{total}{Z}")
    print(f"  Unique cmds : {G}{len(cmds)}{Z}")
    print(f"  Most run    : {B}{top[1]['count']}× {top[0]}{Z}\n")

# ── Dispatch ──────────────────────────────────────────────────────────────────
USAGE = "Usage: doc_cmd.py [run|check|list|search|show|stats] [cmd]"
if len(sys.argv) < 2: cmd_list(); sys.exit(0)
action, *rest = sys.argv[1], sys.argv[2:]
arg = " ".join(rest)
match action:
    case "list":   cmd_list()
    case "check":  cmd_check(arg)
    case "run":    cmd_run(arg)
    case "search": cmd_search(arg)
    case "show":   cmd_show(arg)
    case "stats":  cmd_stats()
    case _:        print(USAGE); sys.exit(1)
