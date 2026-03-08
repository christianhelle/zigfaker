//! Generators for text-related fake data: lorem ipsum paragraphs.

const std = @import("std");
const faker_data = @import("../faker_data.zig");

/// Returns a random lorem ipsum sentence (8–20 words).
pub fn loremText(allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
    const word_count = rng.intRangeAtMost(usize, 8, 20);
    var words: std.ArrayListUnmanaged(u8) = .empty;
    defer words.deinit(allocator);
    for (0..word_count) |i| {
        const idx = rng.uintLessThan(usize, faker_data.lorem_words.len);
        const word = faker_data.lorem_words[idx];
        if (i > 0) try words.append(allocator, ' ');
        try words.appendSlice(allocator, word);
    }
    return words.toOwnedSlice(allocator);
}

// ===== Tests =====

test "loremText contains at least one space (multiple words)" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const text = try loremText(std.testing.allocator, rng);
    defer std.testing.allocator.free(text);
    try std.testing.expect(std.mem.indexOfScalar(u8, text, ' ') != null);
}

test "loremText is non-empty" {
    var prng = std.Random.DefaultPrng.init(42);
    const rng = prng.random();
    const text = try loremText(std.testing.allocator, rng);
    defer std.testing.allocator.free(text);
    try std.testing.expect(text.len > 0);
}
