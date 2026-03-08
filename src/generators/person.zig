//! Generators for person-related fake data: names and job titles.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

fn pickRandom(rng: std.Random, comptime T: type, items: []const T) T {
    return items[rng.uintLessThan(usize, items.len)];
}

/// Returns a random first name.
pub fn firstName(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.first_names);
}

/// Returns a random last name.
pub fn lastName(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.last_names);
}

/// Returns a random full name ("First Last").
pub fn fullName(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const first = pickRandom(rng, []const u8, &faker_data.first_names);
    const last = pickRandom(rng, []const u8, &faker_data.last_names);
    return std.fmt.allocPrint(allocator, "{s} {s}", .{ first, last });
}

/// Returns a random job title.
pub fn jobTitle(rng: std.Random) []const u8 {
    return pickRandom(rng, []const u8, &faker_data.job_titles);
}

// ===== Tests =====

test "firstName returns a known first name" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const name = firstName(rng);
    try std.testing.expect(name.len > 0);
    var found = false;
    for (faker_data.first_names) |n| {
        if (std.mem.eql(u8, name, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "lastName returns a known last name" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const name = lastName(rng);
    try std.testing.expect(name.len > 0);
    var found = false;
    for (faker_data.last_names) |n| {
        if (std.mem.eql(u8, name, n)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "jobTitle returns a known job title" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const title = jobTitle(rng);
    try std.testing.expect(title.len > 0);
    var found = false;
    for (faker_data.job_titles) |t| {
        if (std.mem.eql(u8, title, t)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "fullName contains a space" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const name = try fullName(std.testing.allocator, rng);
    defer std.testing.allocator.free(name);
    try std.testing.expect(std.mem.indexOfScalar(u8, name, ' ') != null);
}
