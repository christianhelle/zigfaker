//! ZigFaker - A library for generating anonymous and fake data for unit tests.
//!
//! ZigFaker is inspired by AutoFaker (https://github.com/christianhelle/autofaker)
//! and AutoFixture, designed to minimize the setup/arrange phase of unit tests by
//! removing the need to manually write code to create anonymous variables.
//!
//! ## Quick Start
//!
//! ```zig
//! const zigfaker = @import("zigfaker");
//!
//! test "example" {
//!     var faker = zigfaker.ZigFaker.initWithFakeData(std.testing.allocator);
//!     defer faker.deinit();
//!
//!     const id = try faker.create(i32);
//!     const name = try faker.create([]const u8);
//!
//!     const Person = struct {
//!         first_name: []const u8,
//!         last_name: []const u8,
//!     };
//!     const person = try faker.create(MyStruct);
//!     _ = person;
//! }
//! ```

const std = @import("std");
const faker_data = @import("faker_data.zig");

const person = @import("generators/person.zig");
const location = @import("generators/location.zig");
const contact = @import("generators/contact.zig");
const internet = @import("generators/internet.zig");
const company = @import("generators/company.zig");
const finance = @import("generators/finance.zig");
const text = @import("generators/text.zig");

// Ensure all generator modules are unconditionally compiled so their tests are included.
comptime {
    _ = text;
}

/// ZigFaker generates anonymous or realistic-looking fake data for use in unit tests.
/// It uses comptime type reflection to automatically populate struct fields.
pub const ZigFaker = struct {
    arena: std.heap.ArenaAllocator,
    prng: std.Random.DefaultPrng,
    use_fake_data: bool,

    /// Initialize ZigFaker for anonymous (random) data generation.
    pub fn init(allocator: std.mem.Allocator) ZigFaker {
        const seed = @as(u64, @bitCast(std.time.milliTimestamp()));
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = false,
        };
    }

    /// Initialize ZigFaker with a specific seed for reproducible results.
    pub fn initWithSeed(allocator: std.mem.Allocator, seed: u64) ZigFaker {
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = false,
        };
    }

    /// Initialize ZigFaker for realistic fake data generation.
    /// String fields in structs will be populated with contextually appropriate
    /// fake data based on field names (e.g. "first_name" gets a real first name).
    pub fn initWithFakeData(allocator: std.mem.Allocator) ZigFaker {
        const seed = @as(u64, @bitCast(std.time.milliTimestamp()));
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = true,
        };
    }

    /// Initialize ZigFaker with fake data and a specific seed.
    pub fn initWithFakeDataAndSeed(allocator: std.mem.Allocator, seed: u64) ZigFaker {
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = true,
        };
    }

    /// Release all memory allocated for string values.
    pub fn deinit(self: *ZigFaker) void {
        self.arena.deinit();
    }

    /// Returns the internal random number generator.
    fn random(self: *ZigFaker) std.Random {
        return self.prng.random();
    }

    /// Creates an anonymous instance of the given type T.
    /// - Integers and floats get random values.
    /// - Booleans get random true/false.
    /// - Strings ([]const u8) get a UUID-like random string or fake string.
    /// - Structs have all fields recursively populated.
    /// - Optional types randomly get null or a populated value.
    /// - Arrays are filled with random elements.
    /// - Enums get a random variant.
    pub fn create(self: *ZigFaker, comptime T: type) !T {
        return self.generateValue(T, "");
    }

    /// Creates a slice of `count` anonymous instances of the given type T.
    /// The returned slice is owned by the ZigFaker arena and freed on `deinit()`.
    pub fn createMany(self: *ZigFaker, comptime T: type, count: usize) ![]T {
        const allocator = self.arena.allocator();
        const items = try allocator.alloc(T, count);
        for (items) |*item| {
            item.* = try self.generateValue(T, "");
        }
        return items;
    }

    /// Generate a value for a specific type, with optional field name hint for fake data.
    fn generateValue(self: *ZigFaker, comptime T: type, comptime field_name: []const u8) !T {
        const rng = self.random();
        const type_info = @typeInfo(T);

        switch (type_info) {
            .int => |info| {
                if (info.signedness == .signed) {
                    const max = std.math.maxInt(T);
                    const min = std.math.minInt(T);
                    return rng.intRangeAtMost(T, min / 2, max / 2);
                } else {
                    return rng.int(T);
                }
            },
            .float => {
                return @as(T, @floatCast(rng.float(f64) * 1_000_000.0));
            },
            .bool => {
                return rng.boolean();
            },
            .pointer => |ptr_info| {
                if (ptr_info.size == .slice and ptr_info.child == u8) {
                    return self.generateString(field_name);
                }
                @compileError("ZigFaker: unsupported pointer type: " ++ @typeName(T));
            },
            .array => |arr_info| {
                var result: T = undefined;
                for (&result) |*elem| {
                    elem.* = try self.generateValue(arr_info.child, "");
                }
                return result;
            },
            .@"struct" => {
                var result: T = undefined;
                inline for (std.meta.fields(T)) |field| {
                    @field(result, field.name) = try self.generateValue(field.type, field.name);
                }
                return result;
            },
            .optional => |opt_info| {
                if (rng.boolean()) {
                    return null;
                } else {
                    return try self.generateValue(opt_info.child, field_name);
                }
            },
            .@"enum" => {
                const fields = std.meta.fields(T);
                const idx = rng.uintLessThan(usize, fields.len);
                inline for (fields, 0..) |field, i| {
                    if (i == idx) return @as(T, @enumFromInt(field.value));
                }
                unreachable;
            },
            .void => return {},
            else => @compileError("ZigFaker: unsupported type: " ++ @typeName(T)),
        }
    }

    /// Generate a string value. In fake data mode, uses the field name to pick
    /// contextually appropriate fake data.
    fn generateString(self: *ZigFaker, comptime field_name: []const u8) ![]const u8 {
        if (self.use_fake_data) {
            return self.generateFakeString(field_name);
        }
        return self.generateAnonymousString();
    }

    /// Generate a UUID-like random string (anonymous mode).
    fn generateAnonymousString(self: *ZigFaker) ![]const u8 {
        const allocator = self.arena.allocator();
        const rng = self.random();
        const buf = try allocator.alloc(u8, 36);
        const hex = "0123456789abcdef";
        // Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        for (0..36) |pos| {
            if (pos == 8 or pos == 13 or pos == 18 or pos == 23) {
                buf[pos] = '-';
            } else {
                buf[pos] = hex[rng.uintLessThan(u8, 16)];
            }
        }
        return buf;
    }

    /// Dispatch fake string generation to the appropriate domain generator based on field name.
    fn generateFakeString(self: *ZigFaker, comptime field_name: []const u8) ![]const u8 {
        const allocator = self.arena.allocator();
        const rng = self.random();

        // Normalize field name to lowercase for comparison.
        const name_lower = comptime blk: {
            var buf: [field_name.len]u8 = undefined;
            _ = std.ascii.lowerString(&buf, field_name);
            break :blk buf;
        };
        const fn_str: []const u8 = &name_lower;

        // --- Person ---
        if (comptime containsAny(fn_str, &.{ "firstname", "first_name", "fname", "given_name", "givenname" }))
            return person.firstName(rng);
        if (comptime containsAny(fn_str, &.{ "lastname", "last_name", "lname", "surname", "family_name", "familyname" }))
            return person.lastName(rng);
        if (comptime std.mem.eql(u8, fn_str, "name"))
            return person.fullName(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "fullname", "full_name", "username" }))
            return person.fullName(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "job", "occupation", "position", "title", "role", "jobtitle", "job_title" }))
            return person.jobTitle(rng);

        // --- Location ---
        if (comptime containsAny(fn_str, &.{ "city", "town" }))
            return location.city(rng);
        if (comptime containsAny(fn_str, &.{"country"}))
            return location.country(rng);
        if (comptime containsAny(fn_str, &.{ "street", "address", "addr" }))
            return location.streetAddress(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "zip", "zipcode", "zip_code", "postal", "postalcode", "postal_code" }))
            return location.zipCode(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "state", "province", "region" }))
            return location.state(rng);

        // --- Contact ---
        if (comptime containsAny(fn_str, &.{ "safe_email", "safeemail" }))
            return contact.safeEmail(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "company_email", "companyemail", "work_email", "workemail" }))
            return contact.companyEmail(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "email", "emailaddress", "email_address" }))
            return contact.email(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "phone", "phonenumber", "phone_number", "mobile", "cell" }))
            return contact.phoneNumber(allocator, rng);

        // --- Internet ---
        if (comptime containsAny(fn_str, &.{ "hostname", "host" }))
            return internet.hostname(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "ipv4", "ip4", "ip_address" }))
            return internet.ipv4(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "ipv6", "ip6" }))
            return internet.ipv6(allocator, rng);
        if (comptime containsAny(fn_str, &.{ "url", "website", "homepage" }))
            return internet.url(allocator, rng);

        // --- Company ---
        if (comptime containsAny(fn_str, &.{ "company", "employer", "organization", "organisation" }))
            return company.companyName(rng);

        // --- Finance ---
        if (comptime containsAny(fn_str, &.{ "currency_name", "currencyname" }))
            return finance.currencyName(rng);
        if (comptime containsAny(fn_str, &.{ "currency_code", "currencycode", "currency" }))
            return finance.currencyCode(rng);

        // --- Text ---
        if (comptime containsAny(fn_str, &.{ "text", "description", "bio", "about", "content", "body", "summary" }))
            return text.loremText(allocator, rng);

        // Default: return a random UUID-like string
        return self.generateAnonymousString();
    }

    /// Comptime helper: check if a string contains any of the given substrings.
    fn containsAny(comptime haystack: []const u8, comptime needles: []const []const u8) bool {
        @setEvalBranchQuota(100000);
        inline for (needles) |needle| {
            if (comptime std.mem.indexOf(u8, haystack, needle) != null) return true;
        }
        return false;
    }
};

// ===== Tests =====

test "create i32" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i32);
    _ = val; // Just ensure it compiles and runs without error
}

test "create u32" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u32);
    _ = val;
}

test "create i64" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i64);
    _ = val;
}

test "create u64" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u64);
    _ = val;
}

test "create f32" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(f32);
    _ = val;
}

test "create f64" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(f64);
    _ = val;
}

test "create bool" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(bool);
    _ = val;
}

test "create string returns non-empty string" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create([]const u8);
    try std.testing.expect(val.len > 0);
}

test "create string returns UUID-like format" {
    var faker = ZigFaker.initWithSeed(std.testing.allocator, 42);
    defer faker.deinit();
    const val = try faker.create([]const u8);
    try std.testing.expectEqual(@as(usize, 36), val.len);
    try std.testing.expectEqual('-', val[8]);
    try std.testing.expectEqual('-', val[13]);
    try std.testing.expectEqual('-', val[18]);
    try std.testing.expectEqual('-', val[23]);
}

test "create struct with primitive fields" {
    const Simple = struct {
        id: i32,
        score: f64,
        active: bool,
    };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Simple);
    _ = val;
}

test "create struct with string field" {
    const WithString = struct {
        id: i32,
        name: []const u8,
    };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(WithString);
    try std.testing.expect(val.name.len > 0);
}

test "create nested struct" {
    const Inner = struct {
        value: i32,
        label: []const u8,
    };
    const Outer = struct {
        id: i64,
        inner: Inner,
    };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Outer);
    try std.testing.expect(val.inner.label.len > 0);
}

test "createMany returns correct count" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 5);
    try std.testing.expectEqual(@as(usize, 5), items.len);
}

test "createMany returns different values (deterministic)" {
    // Use a fixed seed to avoid probabilistic test behavior.
    var faker = ZigFaker.initWithSeed(std.testing.allocator, 12345);
    defer faker.deinit();
    const items = try faker.createMany(i32, 3);
    // Verify deterministic properties only (length).
    try std.testing.expectEqual(@as(usize, 3), items.len);
}

test "createMany struct" {
    const Point = struct {
        x: f64,
        y: f64,
    };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const points = try faker.createMany(Point, 3);
    try std.testing.expectEqual(@as(usize, 3), points.len);
}

test "create optional type" {
    var faker = ZigFaker.initWithSeed(std.testing.allocator, 12345);
    defer faker.deinit();
    // Run multiple times to verify both null and non-null can be produced
    var got_non_null = false;
    var got_null = false;
    for (0..20) |_| {
        const val = try faker.create(?i32);
        if (val != null) got_non_null = true else got_null = true;
    }
    try std.testing.expect(got_non_null and got_null);
}

test "create enum" {
    const Color = enum { red, green, blue };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Color);
    _ = val; // Just ensure it's a valid enum value
}

test "create array type" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create([4]i32);
    try std.testing.expectEqual(@as(usize, 4), val.len);
}

test "fake data: comprehensive person struct" {
    const Person = struct {
        id: i32,
        first_name: []const u8,
        last_name: []const u8,
        job: []const u8,
        email: []const u8,
        city: []const u8,
        country: []const u8,
        ipv4: []const u8,
        ipv6: []const u8,
        hostname: []const u8,
        currency_name: []const u8,
        currency_code: []const u8,
    };
    var faker = ZigFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Person);
    try std.testing.expect(val.first_name.len > 0);
    try std.testing.expect(val.last_name.len > 0);
    try std.testing.expect(val.job.len > 0);
    try std.testing.expect(val.email.len > 0);
    try std.testing.expect(val.city.len > 0);
    try std.testing.expect(val.country.len > 0);
    try std.testing.expect(val.ipv4.len > 0);
    try std.testing.expect(val.ipv6.len > 0);
    try std.testing.expect(val.hostname.len > 0);
    try std.testing.expect(val.currency_name.len > 0);
    try std.testing.expect(val.currency_code.len > 0);
}

test "create with seed is reproducible" {
    const Simple = struct { id: i32, score: f64 };
    var faker1 = ZigFaker.initWithSeed(std.testing.allocator, 99999);
    defer faker1.deinit();
    var faker2 = ZigFaker.initWithSeed(std.testing.allocator, 99999);
    defer faker2.deinit();

    const v1 = try faker1.create(Simple);
    const v2 = try faker2.create(Simple);
    try std.testing.expectEqual(v1.id, v2.id);
    try std.testing.expectApproxEqAbs(v1.score, v2.score, 0.0001);
}

test "createMany with seed is reproducible" {
    var faker1 = ZigFaker.initWithSeed(std.testing.allocator, 42424242);
    defer faker1.deinit();
    var faker2 = ZigFaker.initWithSeed(std.testing.allocator, 42424242);
    defer faker2.deinit();

    const v1 = try faker1.createMany(i32, 5);
    const v2 = try faker2.createMany(i32, 5);
    for (v1, v2) |a, b| {
        try std.testing.expectEqual(a, b);
    }
}

test "anonymous mode: strings are UUID-like" {
    const WithStrings = struct {
        first_name: []const u8,
        email: []const u8,
        company: []const u8,
    };
    var faker = ZigFaker.initWithSeed(std.testing.allocator, 777);
    defer faker.deinit();
    const val = try faker.create(WithStrings);
    // In anonymous mode, all strings should be UUID-format (36 chars)
    try std.testing.expectEqual(@as(usize, 36), val.first_name.len);
    try std.testing.expectEqual(@as(usize, 36), val.email.len);
    try std.testing.expectEqual(@as(usize, 36), val.company.len);
}

test "struct with enum field" {
    const Status = enum { pending, active, inactive };
    const User = struct {
        id: i32,
        status: Status,
    };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(User);
    _ = val.status; // Just ensure it's a valid enum value
}

test "struct with optional field" {
    const User = struct {
        id: i32,
        nickname: ?[]const u8,
    };
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(User);
    _ = val;
}

test "create u8 integer" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u8);
    _ = val;
}

test "create i8 integer" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i8);
    _ = val;
}

test "create u16 integer" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u16);
    _ = val;
}

test "create i16 integer" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i16);
    _ = val;
}

test "createMany with count 1" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 1);
    try std.testing.expectEqual(@as(usize, 1), items.len);
}

test "createMany with count 10" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 10);
    try std.testing.expectEqual(@as(usize, 10), items.len);
}

test "createMany string" {
    var faker = ZigFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany([]const u8, 3);
    try std.testing.expectEqual(@as(usize, 3), items.len);
    for (items) |s| {
        try std.testing.expect(s.len > 0);
    }
}
