# zigfaker

[![build](https://github.com/christianhelle/zigfaker/actions/workflows/build.yml/badge.svg)](https://github.com/christianhelle/zigfaker/actions/workflows/build.yml)

**ZigFaker** is a Zig library designed to minimize the setup/arrange phase of unit tests by removing the need to manually write code to create anonymous test data. It is a Zig port of [AutoFaker](https://github.com/christianhelle/autofaker) and is inspired by [AutoFixture](https://github.com/AutoFixture/AutoFixture).

When writing unit tests you normally start with creating objects that represent the initial state of the test. This phase is called the **arrange** or **setup** phase. In most cases, the system you want to test will force you to specify much more information than you really care about, so you frequently end up creating objects with no influence on the test, just to satisfy the compiler.

ZigFaker can help by generating such anonymous or fake data for you using Zig's comptime type reflection.

---

## Features

- **Anonymous data** — generates random values for all supported types
- **Fake (realistic) data** — generates contextually appropriate fake data based on struct field names (e.g. `first_name`, `email`, `ipv4`)
- **Comptime struct reflection** — automatically populates all fields of any struct type
- **Reproducible output** — seed-based initialization for deterministic test data
- **No external dependencies** — pure Zig, zero dependencies
- **Memory safe** — uses an `ArenaAllocator` for easy cleanup of all generated strings

### Supported types

| Type | Anonymous mode | Fake data mode |
|------|---------------|----------------|
| `i8`, `i16`, `i32`, `i64` | Random signed integer | Same |
| `u8`, `u16`, `u32`, `u64` | Random unsigned integer | Same |
| `f32`, `f64` | Random float | Same |
| `bool` | Random `true`/`false` | Same |
| `[]const u8` | UUID-like string | Contextual fake string |
| Structs | All fields recursively | All fields with field-name hints |
| Nested structs | Recursive | Recursive |
| Optional (`?T`) | Randomly `null` or `T` | Same |
| Enums | Random variant | Same |
| Arrays (`[N]T`) | All elements filled | Same |

### Fake data field name hints

In fake data mode, string fields are populated with realistic data based on field name:

| Field name pattern | Generated data |
|---|---|
| `first_name`, `fname` | Random first name |
| `last_name`, `lname`, `surname` | Random last name |
| `name`, `full_name`, `username` | Random full name |
| `job`, `occupation`, `title`, `role` | Random job title |
| `city`, `town` | Random city name |
| `country` | Random country name |
| `address`, `street`, `addr` | Random street address |
| `zip`, `postal_code` | Random zip/postal code |
| `email` | Random email address |
| `safe_email` | `user123@example.com` |
| `company_email`, `work_email` | Random company email |
| `phone`, `mobile` | Random phone number |
| `hostname`, `host` | Random hostname |
| `ipv4`, `ip4` | Random IPv4 address |
| `ipv6`, `ip6` | Random IPv6 address |
| `url`, `website` | Random HTTPS URL |
| `company`, `organization` | Random company name |
| `currency_name` | Random currency name |
| `currency_code` | Random currency code (e.g. `USD`) |
| `text`, `description`, `body` | Lorem ipsum paragraph |

---

## Requirements

- Zig 0.15.0 or later

---

## Installation

Add ZigFaker to your `build.zig.zon` dependencies by running:

```sh
zig fetch --save https://github.com/christianhelle/zigfaker/archive/refs/heads/main.tar.gz
```

Then in your `build.zig`, add the module to your test step:

```zig
const zigfaker_dep = b.dependency("zigfaker", .{
    .target = target,
    .optimize = optimize,
});
const zigfaker_mod = zigfaker_dep.module("zigfaker");
// Add to your test executable:
exe_tests.root_module.addImport("zigfaker", zigfaker_mod);
```

---

## Quick Start

```zig
const std = @import("std");
const zigfaker = @import("zigfaker");

test "create anonymous integer" {
    var faker = zigfaker.ZigFaker.init(std.testing.allocator);
    defer faker.deinit();

    const value = try faker.create(i32);
    std.debug.print("Random i32: {d}\n", .{value});
}
```

---

## Usage Examples

### Anonymous primitive types

```zig
var faker = zigfaker.ZigFaker.init(allocator);
defer faker.deinit();

const id     = try faker.create(i32);     // e.g. 1453820643
const score  = try faker.create(f64);     // e.g. 812345.67
const active = try faker.create(bool);    // e.g. true
const token  = try faker.create([]const u8); // e.g. "a3f1b2c4-9e8d-7f6a-5b4c-3d2e1f0a9b8c"
```

### Anonymous struct

```zig
const User = struct {
    id: i32,
    score: f64,
    active: bool,
};

var faker = zigfaker.ZigFaker.init(allocator);
defer faker.deinit();

const user = try faker.create(User);
// user.id, user.score, user.active are all populated with random values
```

### Create many instances

```zig
var faker = zigfaker.ZigFaker.init(allocator);
defer faker.deinit();

const users = try faker.createMany(User, 3);
// users is a []User with 3 elements, all populated with random values
```

### Realistic fake data

When you need contextually appropriate data (e.g. for display or integration tests), use
`initWithFakeData`:

```zig
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

var faker = zigfaker.ZigFaker.initWithFakeData(allocator);
defer faker.deinit();

const person = try faker.create(Person);
// person.first_name => "Jennifer"
// person.last_name  => "Martinez"
// person.job        => "Cloud Architect"
// person.email      => "jenniferw42@gmail.com"
// person.city       => "San Francisco"
// person.country    => "Germany"
// person.ipv4       => "192.168.24.100"
// person.ipv6       => "8f3c:0a2b:4d1e:7f9c:1b2a:3e4d:5f6c:7a8b"
// person.hostname   => "api12.smith.io"
// person.currency_name => "British Pound Sterling"
// person.currency_code => "GBP"
```

### Nested structs

```zig
const Address = struct {
    street: []const u8,
    city: []const u8,
    country: []const u8,
};

const Employee = struct {
    id: i32,
    first_name: []const u8,
    last_name: []const u8,
    job: []const u8,
    address: Address,
};

var faker = zigfaker.ZigFaker.initWithFakeData(allocator);
defer faker.deinit();

const emp = try faker.create(Employee);
// emp.address.city => "Los Angeles"
// emp.address.country => "Canada"
```

### Enums

```zig
const Status = enum { pending, active, suspended, closed };

var faker = zigfaker.ZigFaker.init(allocator);
defer faker.deinit();

const status = try faker.create(Status); // one of the four variants
```

### Optional types

```zig
var faker = zigfaker.ZigFaker.init(allocator);
defer faker.deinit();

const maybe_id = try faker.create(?i32); // randomly null or a random i32
```

### Reproducible (seeded) output

For deterministic tests, initialize with a seed:

```zig
var faker = zigfaker.ZigFaker.initWithSeed(allocator, 42);
defer faker.deinit();

const v1 = try faker.create(i32); // always the same value for seed 42
```

---

## API Reference

```zig
pub const ZigFaker = struct {
    /// Initialize with random seed. Strings are UUID-like random values.
    pub fn init(allocator: std.mem.Allocator) ZigFaker

    /// Initialize with a fixed seed for reproducible output.
    pub fn initWithSeed(allocator: std.mem.Allocator, seed: u64) ZigFaker

    /// Initialize in fake data mode. String fields use field names to generate
    /// contextually appropriate fake data (names, emails, IPs, etc.).
    pub fn initWithFakeData(allocator: std.mem.Allocator) ZigFaker

    /// Initialize in fake data mode with a fixed seed.
    pub fn initWithFakeDataAndSeed(allocator: std.mem.Allocator, seed: u64) ZigFaker

    /// Free all memory allocated for strings.
    pub fn deinit(self: *ZigFaker) void

    /// Create a single anonymous/fake instance of type T.
    pub fn create(self: *ZigFaker, comptime T: type) !T

    /// Create a slice of `count` anonymous/fake instances of type T.
    /// The slice is owned by the ZigFaker arena and freed on deinit().
    pub fn createMany(self: *ZigFaker, comptime T: type, count: usize) ![]T
};
```

---

## Building

```sh
zig build          # build the library and example binary
zig build test     # run all tests
zig build run      # run the example application
```

---

## Running Tests

```sh
zig build test
```

All 43 tests cover:

- Primitive types (integers, floats, booleans)
- String generation (anonymous UUID-like and fake data)
- Struct population (anonymous and fake data modes)
- Nested structs
- Optional types
- Enum types
- Array types
- Seeded/reproducible generation
- Fake data field name hints (first_name, email, IPv4, IPv6, etc.)

---

## License

MIT License. See [LICENSE](LICENSE) for details.
