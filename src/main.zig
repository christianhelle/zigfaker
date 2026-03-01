const std = @import("std");
const zigfaker = @import("zigfaker");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    std.debug.print("ZigFaker - Anonymous Data Generation Example\n", .{});
    std.debug.print("============================================\n\n", .{});

    // Anonymous data generation
    {
        var faker = zigfaker.AutoFaker.init(allocator);
        defer faker.deinit();

        const id = try faker.create(i32);
        const score = try faker.create(f64);
        const active = try faker.create(bool);
        const token = try faker.create([]const u8);

        std.debug.print("Anonymous Data:\n", .{});
        std.debug.print("  id:     {d}\n", .{id});
        std.debug.print("  score:  {d:.2}\n", .{score});
        std.debug.print("  active: {}\n", .{active});
        std.debug.print("  token:  {s}\n\n", .{token});
    }

    // Fake data generation
    {
        const Person = struct {
            id: i32,
            first_name: []const u8,
            last_name: []const u8,
            job: []const u8,
            email: []const u8,
            city: []const u8,
            country: []const u8,
        };

        var faker = zigfaker.AutoFaker.initWithFakeData(allocator);
        defer faker.deinit();

        const person = try faker.create(Person);
        std.debug.print("Fake Person Data:\n", .{});
        std.debug.print("  id:      {d}\n", .{person.id});
        std.debug.print("  name:    {s} {s}\n", .{ person.first_name, person.last_name });
        std.debug.print("  job:     {s}\n", .{person.job});
        std.debug.print("  email:   {s}\n", .{person.email});
        std.debug.print("  city:    {s}\n", .{person.city});
        std.debug.print("  country: {s}\n\n", .{person.country});

        // Create many
        const items = try faker.createMany(i32, 3);
        std.debug.print("Many anonymous i32 values:\n", .{});
        for (items) |v| {
            std.debug.print("  {d}\n", .{v});
        }
    }
}

test "main module compiles" {
    // Just ensure imports work
    const t = @import("zigfaker");
    _ = t;
}
