/**
 * doc-cmd — Command Database (TypeScript / Node.js implementation)
 * Native JSON via JSON.parse. No external runtime dependencies.
 * Language choice: TypeScript — type safety for the schema, runs anywhere
 * Node.js is available, compiles to plain JS for distribution.
 */
import * as fs   from "fs";
import * as path from "path";
import * as cp   from "child_process";
import * as readline from "readline";

interface Entry {
  cmd:         string;
  purpose:     string;
  tags:        string[];
  count:       number;
  first_run:   string;
  last_run:    string;
  last_output: string;
}
interface Db {
  version:     string;
  description: string;
  updated:     string;
  commands:    Record<string, Entry>;
}

const R="\x1b[0;31m", G="\x1b[0;32m", Y="\x1b[0;33m",
      B="\x1b[0;34m", C="\x1b[0;36m", D="\x1b[2m",  Z="\x1b[0m";

function repoRoot(): string {
  try { return cp.execSync("git rev-parse --show-toplevel").toString().trim(); }
  catch { return path.resolve(__dirname, "../../../.."); }
}

const ROOT   = repoRoot();
const DB_PATH = path.join(ROOT, "var", "log", "log.commands.json");
const TODAY  = new Date().toISOString().slice(0,10);

function load(): Db {
  return JSON.parse(fs.readFileSync(DB_PATH, "utf-8")) as Db;
}
function save(db: Db): void {
  db.updated = TODAY;
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2), "utf-8");
}
function norm(s: string): string { return s.trim(); }

function cmdList(): void {
  const db = load();
  const entries = Object.values(db.commands).sort((a,b) => b.count - a.count);
  console.log(`\n${C}Command DB — ${B}${entries.length}${C} entries${Z}\n`);
  console.log(`  ${"#".padEnd(3)}  ${"COMMAND".padEnd(54)}  ${"LAST RUN".padEnd(12)}  RUNS`);
  console.log(`  ${"───".padEnd(3)}  ${"─".repeat(54)}  ${"────────────"}  ────`);
  entries.forEach((e,i) =>
    console.log(`  ${String(i+1).padEnd(3)}  ${e.cmd.slice(0,54).padEnd(54)}  ${e.last_run.padEnd(12)}  ${e.count}×`));
  console.log();
}

function cmdCheck(key: string): void {
  const db = load(); const e = db.commands[norm(key)];
  if (e) {
    console.log(`\n${G}● FOUND${Z}  ${B}${key}${Z}`);
    console.log(`  purpose : ${e.purpose}`);
    console.log(`  tags    : ${e.tags.join(", ")}`);
    console.log(`  runs    : ${e.count} (last: ${e.last_run})`);
    console.log(`  output  : ${e.last_output}\n`);
  } else {
    console.log(`${Y}⚠ NOT in database: ${key}${Z}`);
    console.log(`  Add: doc-cmd run "${key}"`);
  }
}

async function cmdRun(key: string): Promise<void> {
  const k = norm(key); const db = load();
  if (db.commands[k]) {
    const e = db.commands[k];
    console.log(`${Y}⚠ KNOWN (${e.count}×, last: ${e.last_run})${Z}`);
    console.log(`  ${D}Cached:${Z} ${e.last_output}`);
    const ans = await prompt("  Re-run? [y/N] ");
    if (ans.toLowerCase() !== "y") {
      e.count++; e.last_run = TODAY; save(db);
      console.log(`${C}ℹ Skipped — using cached.${Z}`); return;
    }
  }
  console.log(`${C}ℹ Running: ${B}${k}${Z}`);
  const out = cp.execSync(k, { encoding:"utf-8", stdio:["inherit","pipe","pipe"] })
    .slice(0, 500);
  console.log(out);
  if (db.commands[k]) {
    db.commands[k].count++; db.commands[k].last_run = TODAY;
    db.commands[k].last_output = out;
    console.log(`${G}✓ Counter: ${db.commands[k].count} runs${Z}`);
  } else {
    db.commands[k] = {cmd:k,purpose:"",tags:["new"],count:1,
                      first_run:TODAY,last_run:TODAY,last_output:out};
    console.log(`${G}✓ Recorded in var/log/log.commands.json${Z}`);
  }
  save(db);
}

function cmdSearch(kw: string): void {
  const db = load(); const k = kw.toLowerCase();
  console.log(`\n${C}Search: "${kw}"${Z}\n`);
  for (const [key,v] of Object.entries(db.commands)) {
    if (key.toLowerCase().includes(k) || v.purpose.toLowerCase().includes(k)
        || v.tags.some(t => t.toLowerCase().includes(k)))
      console.log(`  [${v.count}×]  ${key}\n         └─ ${v.purpose}`);
  }
  console.log();
}

function cmdShow(key: string): void {
  const db = load(); const e = db.commands[norm(key)];
  e ? console.log(JSON.stringify(e, null, 2))
    : console.log(`${Y}⚠ Not found: ${key}${Z}`);
}

function cmdStats(): void {
  const db = load(); const vals = Object.values(db.commands);
  const total = vals.reduce((a,e) => a+e.count, 0);
  const top   = vals.sort((a,b) => b.count-a.count)[0];
  console.log(`\n${C}Command DB Stats${Z}`);
  console.log(`  Total runs  : ${G}${total}${Z}`);
  console.log(`  Unique cmds : ${G}${vals.length}${Z}`);
  console.log(`  Most run    : ${B}${top.count}× ${top.cmd}${Z}\n`);
}

function prompt(q: string): Promise<string> {
  const rl = readline.createInterface({input:process.stdin,output:process.stdout});
  return new Promise(r => rl.question(q, a => { rl.close(); r(a); }));
}

(async () => {
  const [,, action="list", ...rest] = process.argv;
  const arg = rest.join(" ");
  switch (action) {
    case "list":   cmdList();         break;
    case "check":  cmdCheck(arg);     break;
    case "run":    await cmdRun(arg); break;
    case "search": cmdSearch(arg);    break;
    case "show":   cmdShow(arg);      break;
    case "stats":  cmdStats();        break;
    default: console.log("Usage: doc-cmd [list|check|run|search|show|stats] [cmd]"); process.exit(1);
  }
})();
