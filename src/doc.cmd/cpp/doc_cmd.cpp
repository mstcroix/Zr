/**
 * doc_cmd.cpp — Command Database (C++ implementation)
 * Uses popen() + bin/jq.exe for JSON operations.
 * Language choice: C++ — same portability as C with std::string, RAII
 * (no manual free), and std::filesystem for path handling.
 *
 * Build (Linux/WSL2): g++ -O2 -std=c++17 -o doc_cmd doc_cmd.cpp
 * Build (Windows):    g++ -O2 -std=c++17 -o doc_cmd.exe doc_cmd.cpp
 */

#include <cstdlib>
#include <ctime>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace fs = std::filesystem;

/* ANSI colours */
const std::string R="\033[0;31m", G="\033[0;32m", Y="\033[0;33m",
                  B="\033[0;34m", C="\033[0;36m", D="\033[2m",  Z="\033[0m";

/* ── helpers ──────────────────────────────────────────────────────────────── */

static fs::path g_root, g_db, g_jq;

static std::string shell_read(const std::string& cmd) {
    FILE* fp = popen(cmd.c_str(), "r");
    if (!fp) throw std::runtime_error("popen failed: " + cmd);
    std::ostringstream ss;
    char buf[4096];
    while (fgets(buf, sizeof(buf), fp)) ss << buf;
    pclose(fp);
    std::string s = ss.str();
    while (!s.empty() && (s.back() == '\n' || s.back() == '\r')) s.pop_back();
    return s;
}

static std::string today() {
    time_t t = time(nullptr);
    char buf[16];
    strftime(buf, sizeof(buf), "%Y-%m-%d", localtime(&t));
    return buf;
}

/* Escape a string for embedding in a shell command (double-quote safe). */
static std::string esc(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '"' || c == '\\') out += '\\';
        out += c;
    }
    return out;
}

/* Run jq with filter + optional --arg k v pairs */
static std::string jq(const std::string& filter,
                       const std::vector<std::pair<std::string,std::string>>& args = {}) {
    std::ostringstream cmd;
    cmd << '"' << g_jq.string() << "\" -r";
    for (auto& [k,v] : args)
        cmd << " --arg " << k << " \"" << esc(v) << '"';
    cmd << " \"" << esc(filter) << "\" \"" << g_db.string() << '"';
    return shell_read(cmd.str());
}

/* Write updated JSON back via jq */
static void jq_write(const std::string& filter,
                     const std::vector<std::pair<std::string,std::string>>& args = {}) {
    std::string tmp = g_db.string() + ".tmp.json";
    std::ostringstream cmd;
    cmd << '"' << g_jq.string() << '"';
    for (auto& [k,v] : args)
        cmd << " --arg " << k << " \"" << esc(v) << '"';
    cmd << " \"" << esc(filter) << "\" \"" << g_db.string() << '"'
        << " > \"" << tmp << "\" && mv \"" << tmp << "\" \"" << g_db.string() << '"';
    std::system(cmd.str().c_str());
}

static void init() {
    std::string root = shell_read("git rev-parse --show-toplevel 2>/dev/null");
    g_root = root.empty() ? fs::current_path() : fs::path(root);
    g_db   = g_root / "var" / "log" / "log.commands.json";
    g_jq   = g_root / "bin" / "jq.exe";
}

/* ── commands ─────────────────────────────────────────────────────────────── */

static void cmd_list() {
    std::string count = jq(".commands | length");
    std::cout << "\n" << C << "Command DB — " << B << count << C << " entries" << Z << "\n\n";
    std::cout << "  " << std::left
              << std::setw(3)  << "#"   << "  "
              << std::setw(54) << "COMMAND" << "  "
              << std::setw(12) << "LAST RUN" << "  " << "RUNS\n";

    std::string rows = jq(".commands | to_entries[] | \"\\(.value.count) \\(.value.last_run) \\(.key)\"");
    std::istringstream ss(rows);
    std::string line;
    int i = 1;
    while (std::getline(ss, line)) {
        if (line.empty()) continue;
        std::istringstream ls(line);
        std::string cnt, last, key;
        ls >> cnt >> last;
        std::getline(ls, key); if (!key.empty() && key[0]==' ') key = key.substr(1);
        std::string k54 = key.length() > 54 ? key.substr(0,54) : key;
        std::cout << "  " << std::setw(3) << i++ << "  "
                  << std::setw(54) << k54 << "  "
                  << std::setw(12) << last << "  " << cnt << "\xd7\n";
    }
    std::cout << "\n";
}

static void cmd_check(const std::string& key) {
    if (jq(".commands[$k] != null", {{"k",key}}) == "true") {
        std::cout << "\n" << G << "FOUND" << Z << "  " << B << key << Z << "\n";
        std::cout << "  purpose : " << jq(".commands[$k].purpose",    {{"k",key}}) << "\n";
        std::cout << "  runs    : " << jq(".commands[$k].count",      {{"k",key}})
                  << " (last: "     << jq(".commands[$k].last_run",   {{"k",key}}) << ")\n";
        std::cout << "  output  : " << jq(".commands[$k].last_output",{{"k",key}}) << "\n\n";
    } else {
        std::cout << Y << "NOT in database: " << key << Z << "\n"
                  << "  Add: doc_cmd run \"" << key << "\"\n";
    }
}

static void cmd_stats() {
    std::cout << "\n" << C << "Command DB Stats" << Z << "\n";
    std::cout << "  Total runs  : " << G << jq("[.commands[].count] | add")    << Z << "\n";
    std::cout << "  Unique cmds : " << G << jq(".commands | length")            << Z << "\n";
    std::cout << "  Most run    : " << B
              << jq("[.commands|to_entries[]|{k:.key,c:.value.count}]|sort_by(-.c)|.[0]|\"\\(.c)x \\(.k)\"")
              << Z << "\n\n";
}

static void cmd_search(const std::string& kw) {
    std::cout << "\n" << C << "Search: \"" << kw << "\"" << Z << "\n\n";
    std::string filter =
        ".commands|to_entries[]"
        "|select((.key|ascii_downcase|contains($kw))"
        " or (.value.purpose|ascii_downcase|contains($kw)))"
        "|\"  [\\(.value.count)x]  \\(.key)\\n         -- \\(.value.purpose)\"";
    std::cout << jq(filter, {{"kw", kw}}) << "\n\n";
}

static void cmd_show(const std::string& key) {
    if (jq(".commands[$k] != null", {{"k",key}}) == "true")
        std::cout << jq(".commands[$k]", {{"k",key}}) << "\n";
    else
        std::cout << Y << "Not found: " << key << Z << "\n";
}

/* ── main ─────────────────────────────────────────────────────────────────── */

#include <iomanip>

int main(int argc, char* argv[]) {
    init();
    std::string action = argc > 1 ? argv[1] : "list";
    std::string key;
    for (int i = 2; i < argc; ++i) {
        if (i > 2) key += ' ';
        key += argv[i];
    }
    if      (action == "list")   cmd_list();
    else if (action == "check")  cmd_check(key);
    else if (action == "stats")  cmd_stats();
    else if (action == "search") cmd_search(key);
    else if (action == "show")   cmd_show(key);
    else {
        std::cerr << "Usage: doc_cmd [list|check|search|show|stats] [cmd]\n";
        return 1;
    }
    return 0;
}
