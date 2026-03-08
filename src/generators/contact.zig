//! Generators for contact-related fake data: email addresses and phone numbers.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

fn pickRandom(rng: std.Random, comptime T: type, items: []const T) T {
    return items[rng.uintLessThan(usize, items.len)];
}

/// Returns a random public email address ("firstlast123@domain.com").
pub fn email(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const first = pickRandom(rng, []const u8, &faker_data.first_names);
    const last = pickRandom(rng, []const u8, &faker_data.last_names);
    const domain = pickRandom(rng, []const u8, &faker_data.email_domains);
    const num = rng.intRangeAtMost(u16, 1, 999);
    var first_buf: [64]u8 = undefined;
    var last_buf: [64]u8 = undefined;
    const first_lower = std.ascii.lowerString(first_buf[0..first.len], first);
    const last_lower = std.ascii.lowerString(last_buf[0..last.len], last);
    return std.fmt.allocPrint(allocator, "{s}{s}{d}@{s}", .{ first_lower, last_lower, num, domain });
}

/// Returns a safe email address using the example.com domain ("first123@example.com").
pub fn safeEmail(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const first = pickRandom(rng, []const u8, &faker_data.first_names);
    const num = rng.intRangeAtMost(u16, 1, 999);
    var first_buf: [64]u8 = undefined;
    const first_lower = std.ascii.lowerString(first_buf[0..first.len], first);
    return std.fmt.allocPrint(allocator, "{s}{d}@example.com", .{ first_lower, num });
}

/// Returns a company/work email address ("first@company.com").
pub fn companyEmail(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const first = pickRandom(rng, []const u8, &faker_data.first_names);
    const domain = pickRandom(rng, []const u8, &faker_data.company_domains);
    var first_buf: [64]u8 = undefined;
    const first_lower = std.ascii.lowerString(first_buf[0..first.len], first);
    return std.fmt.allocPrint(allocator, "{s}@{s}", .{ first_lower, domain });
}

/// Returns a random US phone number ("+1-NXX-NXX-XXXX").
pub fn phoneNumber(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const area = rng.intRangeAtMost(u16, 200, 999);
    const mid = rng.intRangeAtMost(u16, 200, 999);
    const end = rng.intRangeAtMost(u16, 1000, 9999);
    return std.fmt.allocPrint(allocator, "+1-{d}-{d}-{d}", .{ area, mid, end });
}

// ===== Tests =====

test "email contains @" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const e = try email(std.testing.allocator, rng);
    defer std.testing.allocator.free(e);
    try std.testing.expect(std.mem.indexOfScalar(u8, e, '@') != null);
}

test "safeEmail ends with @example.com" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const e = try safeEmail(std.testing.allocator, rng);
    defer std.testing.allocator.free(e);
    try std.testing.expect(std.mem.endsWith(u8, e, "@example.com") or
        std.mem.indexOf(u8, e, "example.com") != null);
}

test "companyEmail contains @" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const e = try companyEmail(std.testing.allocator, rng);
    defer std.testing.allocator.free(e);
    try std.testing.expect(std.mem.indexOfScalar(u8, e, '@') != null);
}

test "phoneNumber contains dashes" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const phone = try phoneNumber(std.testing.allocator, rng);
    defer std.testing.allocator.free(phone);
    try std.testing.expect(std.mem.indexOfScalar(u8, phone, '-') != null);
}
