//! doc-cmd — Command Database (Rust implementation)
//! Native JSON via serde_json. Zero runtime deps beyond serde.
//! Language choice: Rust — memory-safe, single binary output, fastest
//! startup, compiles to doc-cmd.exe on Windows and doc-cmd on Linux/WSL.

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::collections::HashMap;
use std::io::{self, Write};
use std::path::PathBuf;
use std::process::{Command, exit};

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Entry {
    cmd:         String,
    purpose:     String,
    tags:        Vec<String>,
    count:       u64,
    first_run:   String,
    last_run:    String,
    last_output: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct Db {
    version:     String,
    description: String,
    updated:     String,
    commands:    HashMap<String, Entry>,
}

const R: &str = "\x1b[0;31m"; const G: &str = "\x1b[0;32m";
const Y: &str = "\x1b[0;33m"; const B: &str = "\x1b[0;34m";
const C: &str = "\x1b[0;36m"; const D: &str = "\x1b[2m";
const Z: &str = "\x1b[0m";

fn repo_root() -> PathBuf {
    Command::new("git").args(["rev-parse","--show-toplevel"])
        .output().ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| PathBuf::from(s.trim()))
        .unwrap_or_else(|| std::env::current_exe().unwrap()
            .parent().unwrap().parent().unwrap().parent().unwrap()
            .parent().unwrap().to_path_buf())
}

fn db_path() -> PathBuf { repo_root().join("var").join("log").join("log.commands.json") }
fn today()   -> String  { chrono_today() }

fn chrono_today() -> String {
    // Use date command — avoids the chrono dep
    String::from_utf8(Command::new("date").args(["+%Y-%m-%d"])
        .output().unwrap().stdout).unwrap().trim().to_string()
}

fn load() -> Db {
    let raw = std::fs::read_to_string(db_path())
        .unwrap_or_else(|e| { eprintln!("{R}✗ Cannot read DB: {e}{Z}"); exit(1) });
    serde_json::from_str(&raw)
        .unwrap_or_else(|e| { eprintln!("{R}✗ Invalid JSON: {e}{Z}"); exit(1) })
}

fn save(db: &mut Db) {
    db.updated = today();
    let json = serde_json::to_string_pretty(db).unwrap();
    std::fs::write(db_path(), json).unwrap();
}

fn cmd_list(db: &Db) {
    let mut entries: Vec<_> = db.commands.values().collect();
    entries.sort_by(|a,b| b.count.cmp(&a.count));
    println!("\n{C}Command DB — {B}{}{C} entries{Z}\n", db.commands.len());
    println!("  {:<3}  {:<54}  {:<12}  {}", "#","COMMAND","LAST RUN","RUNS");
    println!("  {:<3}  {:<54}  {:<12}  {}", "───","─".repeat(54),"────────────","────");
    for (i,e) in entries.iter().enumerate() {
        println!("  {:<3}  {:<54}  {:<12}  {}×", i+1, &e.cmd[..e.cmd.len().min(54)], e.last_run, e.count);
    }
    println!();
}

fn cmd_check(db: &Db, key: &str) {
    if let Some(e) = db.commands.get(key) {
        println!("\n{G}● FOUND{Z}  {B}{key}{Z}");
        println!("  purpose : {}", e.purpose);
        println!("  tags    : {}", e.tags.join(", "));
        println!("  runs    : {} (last: {})", e.count, e.last_run);
        println!("  output  : {}\n", e.last_output);
    } else {
        println!("{Y}⚠ NOT in database: {key}{Z}");
        println!("  Add: doc-cmd run \"{key}\"");
    }
}

fn cmd_run(db: &mut Db, key: &str) {
    if let Some(e) = db.commands.get(key) {
        println!("{Y}⚠ KNOWN ({}×, last: {}){Z}", e.count, e.last_run);
        println!("  {D}Cached:{Z} {}", e.last_output);
        print!("  Re-run? [y/N] "); io::stdout().flush().unwrap();
        let mut ans = String::new(); io::stdin().read_line(&mut ans).unwrap();
        if ans.trim().to_lowercase() != "y" {
            let entry = db.commands.get_mut(key).unwrap();
            entry.count += 1; entry.last_run = today(); save(db);
            println!("{C}ℹ Skipped — using cached.{Z}"); return;
        }
    }
    println!("{C}ℹ Running: {B}{key}{Z}");
    let out = Command::new("sh").args(["-c", key]).output().unwrap();
    let output = String::from_utf8_lossy(&[out.stdout.as_slice(), out.stderr.as_slice()].concat())
        .trim().to_string();
    println!("{output}");
    if let Some(e) = db.commands.get_mut(key) {
        e.count += 1; e.last_run = today(); e.last_output = output[..output.len().min(500)].to_string();
        println!("{G}✓ Counter: {} runs{Z}", e.count);
    } else {
        db.commands.insert(key.to_string(), Entry {
            cmd: key.to_string(), purpose: String::new(), tags: vec!["new".into()],
            count: 1, first_run: today(), last_run: today(),
            last_output: output[..output.len().min(500)].to_string(),
        });
        println!("{G}✓ Recorded in logs/log.commands.json{Z}");
    }
    save(db);
}

fn cmd_search(db: &Db, kw: &str) {
    let kw = kw.to_lowercase();
    println!("\n{C}Search: \"{kw}\"{Z}\n");
    for (k,v) in &db.commands {
        if k.to_lowercase().contains(&kw)
           || v.purpose.to_lowercase().contains(&kw)
           || v.tags.iter().any(|t| t.to_lowercase().contains(&kw)) {
            println!("  [{}×]  {}\n         └─ {}", v.count, k, v.purpose);
        }
    }
    println!();
}

fn cmd_show(db: &Db, key: &str) {
    if let Some(e) = db.commands.get(key) {
        println!("{}", serde_json::to_string_pretty(e).unwrap());
    } else {
        println!("{Y}⚠ Not found: {key}{Z}");
    }
}

fn cmd_stats(db: &Db) {
    let total: u64 = db.commands.values().map(|e| e.count).sum();
    let top = db.commands.values().max_by_key(|e| e.count).unwrap();
    println!("\n{C}Command DB Stats{Z}");
    println!("  Total runs  : {G}{total}{Z}");
    println!("  Unique cmds : {G}{}{Z}", db.commands.len());
    println!("  Most run    : {B}{}× {}{Z}\n", top.count, top.cmd);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let action = args.get(1).map(|s| s.as_str()).unwrap_or("list");
    let rest   = args[2..].join(" ");
    let mut db = load();
    match action {
        "list"   => cmd_list(&db),
        "check"  => cmd_check(&db, &rest),
        "run"    => cmd_run(&mut db, &rest),
        "search" => cmd_search(&db, &rest),
        "show"   => cmd_show(&db, &rest),
        "stats"  => cmd_stats(&db),
        _        => { println!("Usage: doc-cmd [list|check|run|search|show|stats] [cmd]"); exit(1); }
    }
}
