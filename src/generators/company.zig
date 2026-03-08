//! Generators for company-related fake data: company names.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

fn pickRandom(rng: std.Random, comptime T: type, items: []const T) T {
    return items[rng.uintLessThan(usize, items.len)];
}

/// Returns a random company name.
pub fn companyName(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.company_names);
}

// ===== Tests =====

test "companyName returns a known company name" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const name = companyName(rng);
    try std.testing.expect(name.len > 0);
    var found = false;
    for (faker_data.company_names) |n| {
        if (std.mem.eql(u8, name, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}
