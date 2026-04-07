/*
 * doc_cmd.c — Command Database (C implementation)
 * Uses popen() to call vendored bin/jq.exe for JSON operations.
 * Language choice: C — maximum portability, compiles on any POSIX system
 * and on Windows via gcc (MinGW/WSL2), produces the smallest binary.
 *
 * Build (Linux/WSL2): gcc -O2 -o doc_cmd doc_cmd.c
 * Build (Windows):    gcc -O2 -o doc_cmd.exe doc_cmd.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* ANSI colours */
#define R "\033[0;31m"
#define G "\033[0;32m"
#define Y "\033[0;33m"
#define B "\033[0;34m"
#define C "\033[0;36m"
#define D "\033[2m"
#define Z "\033[0m"

#define MAX_BUF  (1024 * 64)   /* 64 KB for jq output          */
#define MAX_CMD  (1024 * 4)    /* 4 KB for constructed commands */
#define MAX_PATH (1024)

static char g_root[MAX_PATH];
static char g_db[MAX_PATH];
static char g_jq[MAX_PATH];

/* ── helpers ──────────────────────────────────────────────────────────────── */

static void die(const char *msg) {
    fprintf(stderr, R "✗ %s" Z "\n", msg);
    exit(1);
}

static char *today(void) {
    static char buf[16];
    time_t t = time(NULL);
    struct tm *tm = localtime(&t);
    strftime(buf, sizeof(buf), "%Y-%m-%d", tm);
    return buf;
}

/* Run a shell command and return its output (caller must free). */
static char *shell_read(const char *cmd) {
    FILE *fp = popen(cmd, "r");
    if (!fp) die("popen failed");
    char *buf = malloc(MAX_BUF);
    if (!buf) die("malloc failed");
    size_t n = fread(buf, 1, MAX_BUF - 1, fp);
    pclose(fp);
    buf[n] = '\0';
    /* trim trailing newline */
    while (n > 0 && (buf[n-1] == '\n' || buf[n-1] == '\r')) buf[--n] = '\0';
    return buf;
}

/* Run jq with a filter and optional --arg pairs (NULL-terminated). */
static char *jq_run(const char *filter, ...) {
    char cmd[MAX_CMD];
    snprintf(cmd, sizeof(cmd), "\"%s\" -r", g_jq);

    /* collect --arg pairs from varargs */
    va_list ap;
    va_start(ap, filter);
    const char *k;
    while ((k = va_arg(ap, const char *)) != NULL) {
        const char *v = va_arg(ap, const char *);
        char pair[512];
        snprintf(pair, sizeof(pair), " --arg %s \"%s\"", k, v);
        strncat(cmd, pair, sizeof(cmd) - strlen(cmd) - 1);
    }
    va_end(ap);

    char tail[MAX_CMD];
    snprintf(tail, sizeof(tail), " \"%s\" \"%s\"", filter, g_db);
    strncat(cmd, tail, sizeof(cmd) - strlen(cmd) - 1);
    return shell_read(cmd);
}

/* Write updated JSON back via jq (uses temp file swap). */
static void jq_write(const char *filter, ...) {
    char cmd[MAX_CMD];
    snprintf(cmd, sizeof(cmd), "\"%s\"", g_jq);

    va_list ap;
    va_start(ap, filter);
    const char *k;
    while ((k = va_arg(ap, const char *)) != NULL) {
        const char *v = va_arg(ap, const char *);
        char pair[512];
        snprintf(pair, sizeof(pair), " --arg %s \"%s\"", k, v);
        strncat(cmd, pair, sizeof(cmd) - strlen(cmd) - 1);
    }
    va_end(ap);

    /* write to temp, then move */
    char tmp[MAX_PATH];
    snprintf(tmp, sizeof(tmp), "%s.tmp.json", g_db);
    char tail[MAX_CMD];
    snprintf(tail, sizeof(tail), " \"%s\" \"%s\" > \"%s\" && mv \"%s\" \"%s\"",
             filter, g_db, tmp, tmp, g_db);
    strncat(cmd, tail, sizeof(cmd) - strlen(cmd) - 1);
    system(cmd);
}

/* ── init ─────────────────────────────────────────────────────────────────── */

static void init(void) {
    char *root = shell_read("git rev-parse --show-toplevel 2>/dev/null");
    if (root && strlen(root) > 0) {
        strncpy(g_root, root, MAX_PATH - 1);
        free(root);
    } else {
        strncpy(g_root, ".", MAX_PATH - 1);
    }
    snprintf(g_db, MAX_PATH, "%s/var/log/log.commands.json", g_root);
    snprintf(g_jq, MAX_PATH, "%s/bin/jq.exe", g_root);
}

/* ── commands ─────────────────────────────────────────────────────────────── */

static void cmd_list(void) {
    char *count = jq_run(".commands | length", NULL);
    printf("\n" C "Command DB — " B "%s" C " entries" Z "\n\n", count);
    printf("  %-3s  %-54s  %-12s  %s\n", "#", "COMMAND", "LAST RUN", "RUNS");
    printf("  %-3s  %-54s  %-12s  %s\n", "───",
           "──────────────────────────────────────────────────────",
           "────────────", "────");
    char *rows = jq_run(".commands | to_entries[] | \"\\(.value.count) \\(.value.last_run) \\(.key)\"", NULL);
    /* simple line-by-line print */
    char *line = strtok(rows, "\n");
    int i = 1;
    while (line) {
        char cnt[32], last[16], key[512];
        if (sscanf(line, "%31s %15s %511[^\n]", cnt, last, key) == 3)
            printf("  %-3d  %-54.54s  %-12s  %s\u00d7\n", i++, key, last, cnt);
        line = strtok(NULL, "\n");
    }
    free(count); free(rows);
    printf("\n");
}

static void cmd_check(const char *key) {
    char *exists = jq_run(".commands[$k] != null", "k", key, NULL);
    if (strcmp(exists, "true") == 0) {
        char *purpose = jq_run(".commands[$k].purpose",    "k", key, NULL);
        char *count   = jq_run(".commands[$k].count",      "k", key, NULL);
        char *last    = jq_run(".commands[$k].last_run",   "k", key, NULL);
        char *output  = jq_run(".commands[$k].last_output","k", key, NULL);
        printf("\n" G "● FOUND" Z "  " B "%s" Z "\n", key);
        printf("  purpose : %s\n  runs    : %s (last: %s)\n  output  : %s\n\n",
               purpose, count, last, output);
        free(purpose); free(count); free(last); free(output);
    } else {
        printf(Y "⚠ NOT in database: %s" Z "\n  Add: doc_cmd run \"%s\"\n", key, key);
    }
    free(exists);
}

static void cmd_stats(void) {
    char *total  = jq_run("[.commands[].count] | add", NULL);
    char *unique = jq_run(".commands | length", NULL);
    char *top    = jq_run("[.commands|to_entries[]|{k:.key,c:.value.count}]|sort_by(-.c)|.[0]|\"\\(.c)x \\(.k)\"", NULL);
    printf("\n" C "Command DB Stats" Z "\n");
    printf("  Total runs  : " G "%s" Z "\n", total);
    printf("  Unique cmds : " G "%s" Z "\n", unique);
    printf("  Most run    : " B "%s" Z "\n\n", top);
    free(total); free(unique); free(top);
}

static void cmd_search(const char *kw) {
    printf("\n" C "Search: \"%s\"" Z "\n\n", kw);
    const char *filter =
        ".commands|to_entries[]"
        "|select((.key|ascii_downcase|contains($kw))"
        " or (.value.purpose|ascii_downcase|contains($kw)))"
        "|\"  [\\(.value.count)x]  \\(.key)\\n         -- \\(.value.purpose)\"";
    char *res = jq_run(filter, "kw", kw, NULL);
    printf("%s\n\n", res);
    free(res);
}

static void cmd_show(const char *key) {
    char *exists = jq_run(".commands[$k] != null", "k", key, NULL);
    if (strcmp(exists, "true") == 0) {
        char *entry = jq_run(".commands[$k]", "k", key, NULL);
        printf("%s\n", entry);
        free(entry);
    } else {
        printf(Y "⚠ Not found: %s" Z "\n", key);
    }
    free(exists);
}

/* ── main ─────────────────────────────────────────────────────────────────── */

int main(int argc, char *argv[]) {
    init();
    const char *action = argc > 1 ? argv[1] : "list";
    /* join remaining args as key */
    char key[MAX_CMD] = "";
    for (int i = 2; i < argc; i++) {
        if (i > 2) strncat(key, " ", sizeof(key) - strlen(key) - 1);
        strncat(key, argv[i], sizeof(key) - strlen(key) - 1);
    }
    if      (!strcmp(action,"list"))   cmd_list();
    else if (!strcmp(action,"check"))  cmd_check(key);
    else if (!strcmp(action,"stats"))  cmd_stats();
    else if (!strcmp(action,"search")) cmd_search(key);
    else if (!strcmp(action,"show"))   cmd_show(key);
    else {
        fprintf(stderr, "Usage: doc_cmd [list|check|search|show|stats] [cmd]\n");
        return 1;
    }
    return 0;
}
