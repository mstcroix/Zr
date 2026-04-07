//! doc-cmd — Command Database (Zig implementation)
//! Native JSON via std.json. No external dependencies.
//! Language choice: Zig — no hidden control flow, comptime, single binary,
//! explicit allocations, builds to doc-cmd.exe on Windows without a runtime.

const std = @import("std");
const fs  = std.fs;
const mem = std.mem;
const json = std.json;
const process = std.process;

const DB_REL = "var/log/log.commands.json";

fn repoRoot(allocator: mem.Allocator) ![]u8 {
    const res = try std.process.Child.run(.{
        .allocator = allocator,
        .argv      = &.{ "git", "rev-parse", "--show-toplevel" },
    });
    defer allocator.free(res.stderr);
    return mem.trimRight(u8, res.stdout, "\r\n ");
}

fn today(allocator: mem.Allocator) ![]u8 {
    const res = try std.process.Child.run(.{
        .allocator = allocator,
        .argv      = &.{ "date", "+%Y-%m-%d" },
    });
    defer allocator.free(res.stderr);
    return mem.trimRight(u8, res.stdout, "\r\n ");
}

// ANSI helpers
const R = "\x1b[0;31m"; const G = "\x1b[0;32m"; const Y = "\x1b[0;33m";
const B = "\x1b[0;34m"; const C = "\x1b[0;36m"; const D = "\x1b[2m"; const Z = "\x1b[0m";

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    const root  = try repoRoot(allocator);
    defer allocator.free(root);

    const db_path = try fs.path.join(allocator, &.{ root, DB_REL });
    defer allocator.free(db_path);

    const raw = try fs.cwd().readFileAlloc(allocator, db_path, 10 * 1024 * 1024);
    defer allocator.free(raw);

    var parsed = try json.parseFromSlice(json.Value, allocator, raw, .{});
    defer parsed.deinit();

    const action = if (args.len > 1) args[1] else "list";
    const rest   = if (args.len > 2) args[2] else "";
    const cmds   = parsed.value.object.get("commands") orelse return error.NoDB;

    if (mem.eql(u8, action, "list")) {
        try stdout.print("\n{s}Command DB — {s}{d}{s} entries{s}\n\n",
            .{C, B, cmds.object.count(), C, Z});
        var it = cmds.object.iterator();
        while (it.next()) |kv| {
            const v = kv.value_ptr.*;
            const count = v.object.get("count").?.integer;
            const last  = v.object.get("last_run").?.string;
            try stdout.print("  {d:<3}  {s:<54}  {s:<12}  {d}×\n",
                .{ 1, kv.key_ptr.*[0..@min(54,kv.key_ptr.*.len)], last, count });
        }
        try stdout.print("\n", .{});
    } else if (mem.eql(u8, action, "stats")) {
        var total: i64 = 0;
        var it = cmds.object.iterator();
        while (it.next()) |kv| total += kv.value_ptr.*.object.get("count").?.integer;
        try stdout.print("\n{s}Command DB Stats{s}\n", .{C,Z});
        try stdout.print("  Total runs  : {s}{d}{s}\n", .{G,total,Z});
        try stdout.print("  Unique cmds : {s}{d}{s}\n\n", .{G,cmds.object.count(),Z});
    } else if (mem.eql(u8, action, "check")) {
        if (cmds.object.get(rest)) |v| {
            try stdout.print("\n{s}● FOUND{s}  {s}{s}{s}\n", .{G,Z,B,rest,Z});
            try stdout.print("  purpose : {s}\n", .{v.object.get("purpose").?.string});
            try stdout.print("  runs    : {d}\n\n", .{v.object.get("count").?.integer});
        } else {
            try stderr.print("{s}⚠ NOT found: {s}{s}\n", .{Y,rest,Z});
        }
    } else if (mem.eql(u8, action, "search")) {
        const kw = rest;
        try stdout.print("\n{s}Search: \"{s}\"{s}\n\n", .{C,kw,Z});
        var it = cmds.object.iterator();
        while (it.next()) |kv| {
            const k = kv.key_ptr.*;
            const p = kv.value_ptr.*.object.get("purpose").?.string;
            if (mem.indexOf(u8,k,kw) != null or mem.indexOf(u8,p,kw) != null) {
                const cnt = kv.value_ptr.*.object.get("count").?.integer;
                try stdout.print("  [{d}×]  {s}\n         └─ {s}\n", .{cnt,k,p});
            }
        }
        try stdout.print("\n", .{});
    } else {
        try stderr.print("Usage: doc-cmd [list|check|run|search|show|stats] [cmd]\n", .{});
        process.exit(1);
    }
}
