//! Generators for location-related fake data: cities, countries, addresses, zip codes, and states.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

fn pickRandom(rng: std.Random, comptime T: type, items: []const T) T {
    return items[rng.uintLessThan(usize, items.len)];
}

const states = [_][]const u8{
    "California", "Texas",    "New York", "Florida",
    "Illinois",   "Ohio",     "Georgia",  "Michigan",
    "Washington", "Colorado",
};

/// Returns a random city name.
pub fn city(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.cities);
}

/// Returns a random country name.
pub fn country(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.countries);
}

/// Returns a random street address ("123 Main Street").
pub fn streetAddress(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const num = rng.intRangeAtMost(u16, 1, 9999);
    const street = pickRandom(rng, []const u8, &faker_data.streets);
    return std.fmt.allocPrint(allocator, "{d} {s}", .{ num, street });
}

/// Returns a random 5-digit ZIP code string.
pub fn zipCode(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const code = rng.intRangeAtMost(u32, 10000, 99999);
    return std.fmt.allocPrint(allocator, "{d:0>5}", .{code});
}

/// Returns a random US state name.
pub fn state(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &states);
}

// ===== Tests =====

test "city returns a known city" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const c = city(rng);
    try std.testing.expect(c.len > 0);
    var found = false;
    for (faker_data.cities) |n| {
        if (std.mem.eql(u8, c, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "country returns a known country" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const c = country(rng);
    try std.testing.expect(c.len > 0);
    var found = false;
    for (faker_data.countries) |n| {
        if (std.mem.eql(u8, c, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "streetAddress starts with a digit" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const addr = try streetAddress(std.testing.allocator, rng);
    defer std.testing.allocator.free(addr);
    try std.testing.expect(addr.len > 0);
    try std.testing.expect(addr[0] >= '0' and addr[0] <= '9');
}

test "zipCode has 5 characters" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const zip = try zipCode(std.testing.allocator, rng);
    defer std.testing.allocator.free(zip);
    try std.testing.expectEqual(@as(usize, 5), zip.len);
}

test "state returns a known state" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const s = state(rng);
    try std.testing.expect(s.len > 0);
    var found = false;
    for (states) |n| {
        if (std.mem.eql(u8, s, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}
