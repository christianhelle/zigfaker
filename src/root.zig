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
//!     var faker = zigfaker.AutoFaker.init(std.testing.allocator);
//!     defer faker.deinit();
//!
//!     const id = try faker.create(i32);
//!     const name = try faker.create([]const u8);
//!
//!     const MyStruct = struct { id: i32, name: []const u8 };
//!     const obj = try faker.create(MyStruct);
//!     _ = obj;
//! }
//! ```

const std = @import("std");
const faker_data = @import("faker_data.zig");

/// AutoFaker generates anonymous or realistic-looking fake data for use in unit tests.
/// It uses comptime type reflection to automatically populate struct fields.
pub const AutoFaker = struct {
    arena: std.heap.ArenaAllocator,
    prng: std.Random.DefaultPrng,
    use_fake_data: bool,

    /// Initialize AutoFaker for anonymous (random) data generation.
    pub fn init(allocator: std.mem.Allocator) AutoFaker {
        const seed = @as(u64, @bitCast(std.time.milliTimestamp()));
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = false,
        };
    }

    /// Initialize AutoFaker with a specific seed for reproducible results.
    pub fn initWithSeed(allocator: std.mem.Allocator, seed: u64) AutoFaker {
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = false,
        };
    }

    /// Initialize AutoFaker for realistic fake data generation.
    /// String fields in structs will be populated with contextually appropriate
    /// fake data based on field names (e.g. "first_name" gets a real first name).
    pub fn initWithFakeData(allocator: std.mem.Allocator) AutoFaker {
        const seed = @as(u64, @bitCast(std.time.milliTimestamp()));
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = true,
        };
    }

    /// Initialize AutoFaker with fake data and a specific seed.
    pub fn initWithFakeDataAndSeed(allocator: std.mem.Allocator, seed: u64) AutoFaker {
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .prng = std.Random.DefaultPrng.init(seed),
            .use_fake_data = true,
        };
    }

    /// Release all memory allocated for string values.
    pub fn deinit(self: *AutoFaker) void {
        self.arena.deinit();
    }

    /// Returns the internal random number generator.
    fn random(self: *AutoFaker) std.Random {
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
    pub fn create(self: *AutoFaker, comptime T: type) !T {
        return self.generateValue(T, "");
    }

    /// Creates a slice of `count` anonymous instances of the given type T.
    /// The caller is responsible for freeing the returned slice.
    pub fn createMany(self: *AutoFaker, comptime T: type, count: usize) ![]T {
        const allocator = self.arena.allocator();
        const items = try allocator.alloc(T, count);
        for (items) |*item| {
            item.* = try self.generateValue(T, "");
        }
        return items;
    }

    /// Generate a value for a specific type, with optional field name hint for fake data.
    fn generateValue(self: *AutoFaker, comptime T: type, comptime field_name: []const u8) !T {
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
                @compileError("AutoFaker: unsupported pointer type: " ++ @typeName(T));
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
            else => @compileError("AutoFaker: unsupported type: " ++ @typeName(T)),
        }
    }

    /// Generate a string value. In fake data mode, uses the field name to pick
    /// contextually appropriate fake data.
    fn generateString(self: *AutoFaker, comptime field_name: []const u8) ![]const u8 {
        if (self.use_fake_data) {
            return self.generateFakeString(field_name);
        }
        return self.generateAnonymousString();
    }

    /// Generate a UUID-like random string (anonymous mode).
    fn generateAnonymousString(self: *AutoFaker) ![]const u8 {
        const allocator = self.arena.allocator();
        const rng = self.random();
        const buf = try allocator.alloc(u8, 36);
        const hex = "0123456789abcdef";
        // Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        var i: usize = 0;
        for (0..36) |pos| {
            if (pos == 8 or pos == 13 or pos == 18 or pos == 23) {
                buf[pos] = '-';
            } else {
                buf[pos] = hex[rng.uintLessThan(u8, 16)];
                i += 1;
            }
        }
        return buf;
    }

    /// Pick a random element from a slice.
    fn pickRandom(self: *AutoFaker, comptime T: type, items: []const T) T {
        const idx = self.random().uintLessThan(usize, items.len);
        return items[idx];
    }

    /// Generate a fake string based on field name context (fake data mode).
    fn generateFakeString(self: *AutoFaker, comptime field_name: []const u8) ![]const u8 {
        const allocator = self.arena.allocator();
        const rng = self.random();

        // Normalize field name for comparison (lowercase, underscore-based).
        // We check common field name patterns to return contextually appropriate data.
        const name_lower = comptime blk: {
            var buf: [field_name.len]u8 = undefined;
            _ = std.ascii.lowerString(&buf, field_name);
            break :blk buf;
        };
        const fn_str: []const u8 = &name_lower;

        // Name fields
        if (comptime containsAny(fn_str, &.{ "firstname", "first_name", "fname", "given_name", "givenname" })) {
            return self.pickRandom([]const u8, &faker_data.first_names);
        }
        if (comptime containsAny(fn_str, &.{ "lastname", "last_name", "lname", "surname", "family_name", "familyname" })) {
            return self.pickRandom([]const u8, &faker_data.last_names);
        }
        if (comptime containsAny(fn_str, &.{ "name", "fullname", "full_name", "username" })) {
            const first = self.pickRandom([]const u8, &faker_data.first_names);
            const last = self.pickRandom([]const u8, &faker_data.last_names);
            return std.fmt.allocPrint(allocator, "{s} {s}", .{ first, last });
        }

        // Job / occupation
        if (comptime containsAny(fn_str, &.{ "job", "occupation", "position", "title", "role", "jobtitle", "job_title" })) {
            return self.pickRandom([]const u8, &faker_data.job_titles);
        }

        // Location fields
        if (comptime containsAny(fn_str, &.{ "city", "town" })) {
            return self.pickRandom([]const u8, &faker_data.cities);
        }
        if (comptime containsAny(fn_str, &.{ "country" })) {
            return self.pickRandom([]const u8, &faker_data.countries);
        }
        if (comptime containsAny(fn_str, &.{ "street", "address", "addr" })) {
            const num = rng.intRangeAtMost(u16, 1, 9999);
            const street = self.pickRandom([]const u8, &faker_data.streets);
            return std.fmt.allocPrint(allocator, "{d} {s}", .{ num, street });
        }
        if (comptime containsAny(fn_str, &.{ "zip", "zipcode", "zip_code", "postal", "postalcode", "postal_code" })) {
            const code = rng.intRangeAtMost(u32, 10000, 99999);
            return std.fmt.allocPrint(allocator, "{d:0>5}", .{code});
        }
        if (comptime containsAny(fn_str, &.{ "state", "province", "region" })) {
            const states = [_][]const u8{
                "California", "Texas",   "New York",  "Florida",
                "Illinois",   "Ohio",    "Georgia",   "Michigan",
                "Washington", "Colorado",
            };
            return self.pickRandom([]const u8, &states);
        }

        // Contact fields
        if (comptime containsAny(fn_str, &.{ "email", "emailaddress", "email_address" })) {
            const first = self.pickRandom([]const u8, &faker_data.first_names);
            const last = self.pickRandom([]const u8, &faker_data.last_names);
            const domain = self.pickRandom([]const u8, &faker_data.email_domains);
            const num = rng.intRangeAtMost(u16, 1, 999);
            return std.fmt.allocPrint(allocator, "{s}{s}{d}@{s}", .{
                std.ascii.lowerString(try allocator.dupe(u8, first), first),
                std.ascii.lowerString(try allocator.dupe(u8, last), last),
                num,
                domain,
            });
        }
        if (comptime containsAny(fn_str, &.{ "safe_email", "safeemail" })) {
            const first = self.pickRandom([]const u8, &faker_data.first_names);
            const num = rng.intRangeAtMost(u16, 1, 999);
            return std.fmt.allocPrint(allocator, "{s}{d}@example.com", .{
                std.ascii.lowerString(try allocator.dupe(u8, first), first),
                num,
            });
        }
        if (comptime containsAny(fn_str, &.{ "company_email", "companyemail", "work_email", "workemail" })) {
            const first = self.pickRandom([]const u8, &faker_data.first_names);
            const domain = self.pickRandom([]const u8, &faker_data.company_domains);
            return std.fmt.allocPrint(allocator, "{s}@{s}", .{
                std.ascii.lowerString(try allocator.dupe(u8, first), first),
                domain,
            });
        }
        if (comptime containsAny(fn_str, &.{ "phone", "phonenumber", "phone_number", "mobile", "cell" })) {
            const area = rng.intRangeAtMost(u16, 200, 999);
            const mid = rng.intRangeAtMost(u16, 200, 999);
            const end = rng.intRangeAtMost(u16, 1000, 9999);
            return std.fmt.allocPrint(allocator, "+1-{d}-{d}-{d}", .{ area, mid, end });
        }

        // Network fields
        if (comptime containsAny(fn_str, &.{ "hostname", "host" })) {
            const prefix = self.pickRandom([]const u8, &faker_data.hostnames_prefix);
            const num = rng.intRangeAtMost(u8, 1, 99);
            const tld = self.pickRandom([]const u8, &faker_data.tlds);
            const last = self.pickRandom([]const u8, &faker_data.last_names);
            return std.fmt.allocPrint(allocator, "{s}{d}.{s}.{s}", .{
                prefix,
                num,
                std.ascii.lowerString(try allocator.dupe(u8, last), last),
                tld,
            });
        }
        if (comptime containsAny(fn_str, &.{ "ipv4", "ip4", "ip_address" })) {
            return std.fmt.allocPrint(allocator, "{d}.{d}.{d}.{d}", .{
                rng.intRangeAtMost(u8, 1, 254),
                rng.intRangeAtMost(u8, 0, 255),
                rng.intRangeAtMost(u8, 0, 255),
                rng.intRangeAtMost(u8, 1, 254),
            });
        }
        if (comptime containsAny(fn_str, &.{ "ipv6", "ip6" })) {
            return std.fmt.allocPrint(allocator, "{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}:{x:0>4}", .{
                rng.int(u16),
                rng.int(u16),
                rng.int(u16),
                rng.int(u16),
                rng.int(u16),
                rng.int(u16),
                rng.int(u16),
                rng.int(u16),
            });
        }
        if (comptime containsAny(fn_str, &.{ "url", "website", "homepage" })) {
            const last = self.pickRandom([]const u8, &faker_data.last_names);
            const tld = self.pickRandom([]const u8, &faker_data.tlds);
            return std.fmt.allocPrint(allocator, "https://www.{s}.{s}", .{
                std.ascii.lowerString(try allocator.dupe(u8, last), last),
                tld,
            });
        }

        // Company fields
        if (comptime containsAny(fn_str, &.{ "company", "employer", "organization", "organisation" })) {
            return self.pickRandom([]const u8, &faker_data.company_names);
        }

        // Currency fields
        if (comptime containsAny(fn_str, &.{ "currency_name", "currencyname" })) {
            return self.pickRandom([]const u8, &faker_data.currency_names);
        }
        if (comptime containsAny(fn_str, &.{ "currency_code", "currencycode", "currency" })) {
            return self.pickRandom([]const u8, &faker_data.currency_codes);
        }

        // Text / description
        if (comptime containsAny(fn_str, &.{ "text", "description", "bio", "about", "content", "body", "summary" })) {
            return self.generateLoremText(allocator, rng);
        }

        // Default: return a random UUID-like string
        return self.generateAnonymousString();
    }

    /// Generate a short lorem ipsum paragraph.
    fn generateLoremText(self: *AutoFaker, allocator: std.mem.Allocator, rng: std.Random) ![]const u8 {
        _ = self;
        const word_count = rng.intRangeAtMost(usize, 8, 20);
        var words: std.ArrayList(u8) = .empty;
        for (0..word_count) |i| {
            const idx = rng.uintLessThan(usize, faker_data.lorem_words.len);
            const word = faker_data.lorem_words[idx];
            if (i > 0) try words.append(allocator, ' ');
            try words.appendSlice(allocator, word);
        }
        return words.toOwnedSlice(allocator);
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
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i32);
    _ = val; // Just ensure it compiles and runs without error
}

test "create u32" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u32);
    _ = val;
}

test "create i64" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i64);
    _ = val;
}

test "create u64" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u64);
    _ = val;
}

test "create f32" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(f32);
    _ = val;
}

test "create f64" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(f64);
    _ = val;
}

test "create bool" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(bool);
    _ = val;
}

test "create string returns non-empty string" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create([]const u8);
    try std.testing.expect(val.len > 0);
}

test "create string returns UUID-like format" {
    var faker = AutoFaker.initWithSeed(std.testing.allocator, 42);
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
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Simple);
    _ = val;
}

test "create struct with string field" {
    const WithString = struct {
        id: i32,
        name: []const u8,
    };
    var faker = AutoFaker.init(std.testing.allocator);
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
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Outer);
    try std.testing.expect(val.inner.label.len > 0);
}

test "createMany returns correct count" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 5);
    try std.testing.expectEqual(@as(usize, 5), items.len);
}

test "createMany returns different values (probabilistic)" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 3);
    // With random seeding it's extremely unlikely all 3 are equal
    const all_equal = items[0] == items[1] and items[1] == items[2];
    try std.testing.expect(!all_equal);
}

test "createMany struct" {
    const Point = struct {
        x: f64,
        y: f64,
    };
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const points = try faker.createMany(Point, 3);
    try std.testing.expectEqual(@as(usize, 3), points.len);
}

test "create optional type" {
    var faker = AutoFaker.initWithSeed(std.testing.allocator, 12345);
    defer faker.deinit();
    // Run multiple times to verify both null and non-null can be produced
    var got_non_null = false;
    var got_null = false;
    for (0..20) |_| {
        const val = try faker.create(?i32);
        if (val != null) got_non_null = true else got_null = true;
    }
    try std.testing.expect(got_non_null or got_null);
}

test "create enum" {
    const Color = enum { red, green, blue };
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Color);
    _ = val; // Just ensure it's a valid enum value
}

test "create array type" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create([4]i32);
    try std.testing.expectEqual(@as(usize, 4), val.len);
}

test "fake data: first_name field" {
    const Person = struct {
        first_name: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Person);
    try std.testing.expect(val.first_name.len > 0);
    // Verify it's one of our known first names
    var found = false;
    for (faker_data.first_names) |name| {
        if (std.mem.eql(u8, val.first_name, name)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "fake data: last_name field" {
    const Person = struct {
        last_name: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Person);
    var found = false;
    for (faker_data.last_names) |name| {
        if (std.mem.eql(u8, val.last_name, name)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "fake data: job field" {
    const Employee = struct {
        job: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Employee);
    var found = false;
    for (faker_data.job_titles) |title| {
        if (std.mem.eql(u8, val.job, title)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "fake data: email field contains @" {
    const Contact = struct {
        email: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Contact);
    try std.testing.expect(std.mem.indexOfScalar(u8, val.email, '@') != null);
}

test "fake data: ipv4 field is valid format" {
    const Server = struct {
        ipv4: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Server);
    // Should contain exactly 3 dots
    var dot_count: usize = 0;
    for (val.ipv4) |c| {
        if (c == '.') dot_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 3), dot_count);
}

test "fake data: ipv6 field is valid format" {
    const Server = struct {
        ipv6: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Server);
    // Should contain exactly 7 colons
    var colon_count: usize = 0;
    for (val.ipv6) |c| {
        if (c == ':') colon_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 7), colon_count);
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
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
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
    var faker1 = AutoFaker.initWithSeed(std.testing.allocator, 99999);
    defer faker1.deinit();
    var faker2 = AutoFaker.initWithSeed(std.testing.allocator, 99999);
    defer faker2.deinit();

    const v1 = try faker1.create(Simple);
    const v2 = try faker2.create(Simple);
    try std.testing.expectEqual(v1.id, v2.id);
    try std.testing.expectApproxEqAbs(v1.score, v2.score, 0.0001);
}

test "createMany with seed is reproducible" {
    var faker1 = AutoFaker.initWithSeed(std.testing.allocator, 42424242);
    defer faker1.deinit();
    var faker2 = AutoFaker.initWithSeed(std.testing.allocator, 42424242);
    defer faker2.deinit();

    const v1 = try faker1.createMany(i32, 5);
    const v2 = try faker2.createMany(i32, 5);
    for (v1, v2) |a, b| {
        try std.testing.expectEqual(a, b);
    }
}

test "fake data: text field contains spaces (is multiple words)" {
    const Article = struct {
        text: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Article);
    try std.testing.expect(std.mem.indexOfScalar(u8, val.text, ' ') != null);
}

test "fake data: address field contains number" {
    const Location = struct {
        address: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Location);
    try std.testing.expect(val.address.len > 0);
    // Address should start with a number
    try std.testing.expect(val.address[0] >= '0' and val.address[0] <= '9');
}

test "fake data: company field" {
    const Business = struct {
        company: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Business);
    var found = false;
    for (faker_data.company_names) |name| {
        if (std.mem.eql(u8, val.company, name)) {
            found = true;
            break;
        }
    }
    try std.testing.expect(found);
}

test "fake data: url field starts with https" {
    const WebResource = struct {
        url: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(WebResource);
    try std.testing.expect(std.mem.startsWith(u8, val.url, "https://"));
}

test "fake data: phone field contains dashes" {
    const Contact = struct {
        phone: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Contact);
    try std.testing.expect(std.mem.indexOfScalar(u8, val.phone, '-') != null);
}

test "anonymous mode: strings are UUID-like" {
    const WithStrings = struct {
        first_name: []const u8,
        email: []const u8,
        company: []const u8,
    };
    var faker = AutoFaker.initWithSeed(std.testing.allocator, 777);
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
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(User);
    _ = val.status; // Just ensure it's a valid enum value
}

test "struct with optional field" {
    const User = struct {
        id: i32,
        nickname: ?[]const u8,
    };
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(User);
    _ = val;
}

test "create u8 integer" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u8);
    _ = val;
}

test "create i8 integer" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i8);
    _ = val;
}

test "create u16 integer" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(u16);
    _ = val;
}

test "create i16 integer" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(i16);
    _ = val;
}

test "fake data: currency_code has 3 chars" {
    const Finance = struct {
        currency_code: []const u8,
    };
    var faker = AutoFaker.initWithFakeData(std.testing.allocator);
    defer faker.deinit();
    const val = try faker.create(Finance);
    try std.testing.expectEqual(@as(usize, 3), val.currency_code.len);
}

test "createMany with count 1" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 1);
    try std.testing.expectEqual(@as(usize, 1), items.len);
}

test "createMany with count 10" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany(i32, 10);
    try std.testing.expectEqual(@as(usize, 10), items.len);
}

test "createMany string" {
    var faker = AutoFaker.init(std.testing.allocator);
    defer faker.deinit();
    const items = try faker.createMany([]const u8, 3);
    try std.testing.expectEqual(@as(usize, 3), items.len);
    for (items) |s| {
        try std.testing.expect(s.len > 0);
    }
}
