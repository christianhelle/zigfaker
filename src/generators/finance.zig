//! Generators for finance-related fake data: currency names and codes.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

fn pickRandom(rng: std.Random, comptime T: type, items: []const T) T {
    return items[rng.uintLessThan(usize, items.len)];
}

/// Returns a random currency name (e.g. "US Dollar").
pub fn currencyName(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.currency_names);
}

/// Returns a random ISO 4217 currency code (e.g. "USD").
pub fn currencyCode(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.currency_codes);
}

// ===== Tests =====

test "currencyName returns a known currency name" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const name = currencyName(rng);
    try std.testing.expect(name.len > 0);
    var found = false;
    for (faker_data.currency_names) |n| {
        if (std.mem.eql(u8, name, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "currencyCode has 3 characters" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const code = currencyCode(rng);
    try std.testing.expectEqual(@as(usize, 3), code.len);
}
