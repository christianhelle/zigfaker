//! Generators for internet-related fake data: hostnames, IP addresses, and URLs.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

fn pickRandom(rng: std.Random, comptime T: type, items: []const T) T {
    return items[rng.uintLessThan(usize, items.len)];
}

/// Returns a random hostname ("prefix42.lastname.tld").
pub fn hostname(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const prefix = pickRandom(rng, []const u8, &faker_data.hostnames_prefix);
    const num = rng.intRangeAtMost(u8, 1, 99);
    const tld = pickRandom(rng, []const u8, &faker_data.tlds);
    const last = pickRandom(rng, []const u8, &faker_data.last_names);
    var last_buf: [64]u8 = undefined;
    const last_lower = std.ascii.lowerString(last_buf[0..last.len], last);
    return std.fmt.allocPrint(allocator, "{s}{d}.{s}.{s}", .{ prefix, num, last_lower, tld });
}

/// Returns a random IPv4 address ("d.d.d.d").
pub fn ipv4(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{d}.{d}.{d}.{d}", .{
        rng.intRangeAtMost(u8, 1, 254),
        rng.intRangeAtMost(u8, 0, 255),
        rng.intRangeAtMost(u8, 0, 255),
        rng.intRangeAtMost(u8, 1, 254),
    });
}

/// Returns a random IPv6 address (full 8-group hex notation).
pub fn ipv6(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    return std.fmt.allocPrint(
        allocator,
        "{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}",
        .{
            rng.int(u16), rng.int(u16), rng.int(u16), rng.int(u16),
            rng.int(u16), rng.int(u16), rng.int(u16), rng.int(u16),
        },
    );
}

/// Returns a random HTTPS URL ("https://www.name.tld").
pub fn url(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const last = pickRandom(rng, []const u8, &faker_data.last_names);
    const tld = pickRandom(rng, []const u8, &faker_data.tlds);
    var last_buf: [64]u8 = undefined;
    const last_lower = std.ascii.lowerString(last_buf[0..last.len], last);
    return std.fmt.allocPrint(allocator, "https://www.{s}.{s}", .{ last_lower, tld });
}

// ===== Tests =====

test "ipv4 contains exactly 3 dots" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const addr = try ipv4(std.testing.allocator, rng);
    defer std.testing.allocator.free(addr);
    var dot_count: usize = 0;
    for (addr) |c| {
        if (c == '.') dot_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), dot_count);
}

test "ipv6 contains exactly 7 colons" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const addr = try ipv6(std.testing.allocator, rng);
    defer std.testing.allocator.free(addr);
    var colon_count: usize = 0;
    for (addr) |c| {
        if (c == ':') colon_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 7), colon_count);
}

test "hostname is non-empty" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const host = try hostname(std.testing.allocator, rng);
    defer std.testing.allocator.free(host);
    try std.testing.expect(host.len > 0);
}

test "url starts with https://" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const u = try url(std.testing.allocator, rng);
    defer std.testing.allocator.free(u);
    try std.testing.expect(std.mem.startsWith(u8, u, "https://"));
}
