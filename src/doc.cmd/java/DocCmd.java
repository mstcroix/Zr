/**
 * DocCmd.java — Command Database (Java implementation)
 * Uses ProcessBuilder + vendored bin/jq.exe for JSON operations.
 * Language choice: Java — runs anywhere a JVM exists, strong typing,
 * single .class file deployment, zero external JAR dependencies.
 *
 * Build:  javac DocCmd.java
 * Run:    java -cp . DocCmd [list|check|run|search|show|stats] [cmd]
 */
import java.io.*;
import java.nio.file.*;
import java.time.LocalDate;
import java.util.*;

public class DocCmd {

    static final String R="\033[0;31m", G="\033[0;32m", Y="\033[0;33m",
                        B="\033[0;34m", C="\033[0;36m", D="\033[2m",  Z="\033[0m";

    static Path repoRoot() {
        try {
            Process p = new ProcessBuilder("git","rev-parse","--show-toplevel")
                .redirectErrorStream(true).start();
            String out = new String(p.getInputStream().readAllBytes()).trim();
            if (p.waitFor() == 0 && !out.isEmpty()) return Path.of(out);
        } catch (Exception ignored) {}
        return Path.of(System.getProperty("user.dir"));
    }

    static final Path ROOT  = repoRoot();
    static final Path DB    = ROOT.resolve("var/log/log.commands.json");
    static final Path JQ    = ROOT.resolve("bin/jq.exe");
    static final String TODAY = LocalDate.now().toString();

    static String run(List<String> cmd) throws Exception {
        ProcessBuilder pb = new ProcessBuilder(cmd).redirectErrorStream(true);
        Process p = pb.start();
        String out = new String(p.getInputStream().readAllBytes()).trim();
        p.waitFor();
        return out;
    }

    static String jq(String filter, String... argPairs) throws Exception {
        List<String> cmd = new ArrayList<>();
        cmd.add(JQ.toString()); cmd.add("-r");
        for (int i = 0; i + 1 < argPairs.length; i += 2) {
            cmd.add("--arg"); cmd.add(argPairs[i]); cmd.add(argPairs[i+1]);
        }
        cmd.add(filter); cmd.add(DB.toString());
        return run(cmd);
    }

    static void jqWrite(String filter, String... argPairs) throws Exception {
        List<String> cmd = new ArrayList<>();
        cmd.add(JQ.toString());
        for (int i = 0; i + 1 < argPairs.length; i += 2) {
            cmd.add("--arg"); cmd.add(argPairs[i]); cmd.add(argPairs[i+1]);
        }
        cmd.add(filter); cmd.add(DB.toString());
        Path tmp = Files.createTempFile("doccmd", ".json");
        new ProcessBuilder(cmd).redirectOutput(tmp.toFile()).start().waitFor();
        Files.move(tmp, DB, StandardCopyOption.REPLACE_EXISTING);
    }

    static void cmdList() throws Exception {
        int count = Integer.parseInt(jq(".commands | length"));
        System.out.printf("%n%sCommand DB %s%d%s entries%s%n%n", C, B, count, C, Z);
        System.out.printf("  %-3s  %-54s  %-12s  %s%n", "#", "COMMAND", "LAST RUN", "RUNS");
        System.out.printf("  %-3s  %-54s  %-12s  %s%n", "───", "─".repeat(54), "────────────", "────");
        String raw = jq(".commands | to_entries[] | \"\\(.value.count) \\(.value.last_run) \\(.key)\"");
        String[] rows = raw.split("\n");
        Arrays.sort(rows, (a,b2) -> {
            try { return Integer.parseInt(b2.split(" ")[0]) - Integer.parseInt(a.split(" ")[0]); }
            catch (Exception e) { return 0; }
        });
        for (int i = 0; i < rows.length; i++) {
            if (rows[i].isBlank()) continue;
            String[] p = rows[i].split(" ", 3);
            String key = p.length > 2 ? p[2] : "";
            System.out.printf("  %-3d  %-54s  %-12s  %s\u00d7%n",
                i+1, key.length()>54?key.substring(0,54):key, p[1], p[0]);
        }
        System.out.println();
    }

    static void cmdCheck(String key) throws Exception {
        if ("true".equals(jq(".commands[$k] != null", "k", key))) {
            System.out.printf("%n%s FOUND%s  %s%s%s%n", G, Z, B, key, Z);
            System.out.println("  purpose : " + jq(".commands[$k].purpose",    "k", key));
            System.out.println("  tags    : " + jq(".commands[$k].tags|join(\", \")", "k", key));
            System.out.println("  runs    : " + jq(".commands[$k].count",      "k", key)
                             + " (last: "     + jq(".commands[$k].last_run",   "k", key) + ")");
            System.out.println("  output  : " + jq(".commands[$k].last_output","k", key) + "\n");
        } else {
            System.out.printf("%s NOT in database: %s%s%n  Add: java DocCmd run \"%s\"%n", Y, key, Z, key);
        }
    }

    static void cmdRun(String key) throws Exception {
        boolean known = "true".equals(jq(".commands[$k] != null", "k", key));
        if (known) {
            System.out.printf("%s KNOWN (%s x, last: %s)%s%n",
                Y, jq(".commands[$k].count","k",key), jq(".commands[$k].last_run","k",key), Z);
            System.out.println("  " + D + "Cached: " + Z + jq(".commands[$k].last_output","k",key));
            System.out.print("  Re-run? [y/N] ");
            if (!new Scanner(System.in).nextLine().trim().equalsIgnoreCase("y")) {
                jqWrite(".commands[$k].count+=1|.commands[$k].last_run=$d|.updated=$d","k",key,"d",TODAY);
                System.out.println(C + "Skipped - using cached." + Z); return;
            }
        }
        System.out.println(C + "Running: " + B + key + Z);
        Process p = new ProcessBuilder("bash","-c",key).redirectErrorStream(true).start();
        String output = new String(p.getInputStream().readAllBytes()).trim();
        p.waitFor();
        if (output.length() > 500) output = output.substring(0, 500);
        System.out.println(output);
        if (known) {
            jqWrite(".commands[$k].count+=1|.commands[$k].last_run=$d|.commands[$k].last_output=$o|.updated=$d",
                "k",key,"d",TODAY,"o",output);
            System.out.println(G + " Counter updated" + Z);
        } else {
            jqWrite(".commands[$k]={cmd:$k,purpose:\"\",tags:[\"new\"],count:1,first_run:$d,last_run:$d,last_output:$o}|.updated=$d",
                "k",key,"d",TODAY,"o",output);
            System.out.println(G + " Recorded in var/log/log.commands.json" + Z);
        }
    }

    static void cmdSearch(String kw) throws Exception {
        System.out.printf("%n%sSearch: \"%s\"%s%n%n", C, kw, Z);
        String filter = ".commands|to_entries[]|select((.key|ascii_downcase|contains($kw)) or (.value.purpose|ascii_downcase|contains($kw)))|\"  [\\(.value.count)x]  \\(.key)\\n         -- \\(.value.purpose)\"";
        System.out.println(jq(filter, "kw", kw.toLowerCase()) + "\n");
    }

    static void cmdShow(String key) throws Exception {
        if ("true".equals(jq(".commands[$k] != null","k",key)))
            System.out.println(jq(".commands[$k]","k",key));
        else
            System.out.printf("%s Not found: %s%s%n", Y, key, Z);
    }

    static void cmdStats() throws Exception {
        System.out.printf("%n%sCommand DB Stats%s%n", C, Z);
        System.out.printf("  Total runs  : %s%s%s%n", G, jq("[.commands[].count]|add"), Z);
        System.out.printf("  Unique cmds : %s%s%s%n", G, jq(".commands|length"), Z);
        System.out.printf("  Most run    : %s%s%s%n%n", B,
            jq("[.commands|to_entries[]|{k:.key,c:.value.count}]|sort_by(-.c)|.[0]|\"\\(.c)x \\(.k)\""), Z);
    }

    public static void main(String[] args) throws Exception {
        String action = args.length > 0 ? args[0] : "list";
        String rest   = args.length > 1 ? String.join(" ", Arrays.copyOfRange(args,1,args.length)) : "";
        switch (action) {
            case "list"   -> cmdList();
            case "check"  -> cmdCheck(rest);
            case "run"    -> cmdRun(rest);
            case "search" -> cmdSearch(rest);
            case "show"   -> cmdShow(rest);
            case "stats"  -> cmdStats();
            default       -> { System.out.println("Usage: java DocCmd [list|check|run|search|show|stats] [cmd]"); System.exit(1); }
        }
    }
}
