# Ruby XID Performance Optimization Design

**Date:** 2026-02-23
**Goal:** Optimize speed and memory efficiency for generate-and-stringify workload
**Constraint:** Maintain backward compatibility (all existing tests must pass)

## Problem Statement

Current implementation has performance bottlenecks:
- Double conversion: binary → array → binary for encoding
- Repeated allocations in hot paths
- Inefficient hash/array operations
- Unnecessary intermediate objects

Primary use case: Generate XID and immediately convert to string (`Xid.new.to_s`)

## Optimization Strategy

### 1. Core Storage Change

**Current:** Store `@value` as 12-element array
```ruby
@value = @@generator.generate.unpack('C12')  # Array of 12 integers
```

**Optimized:** Store `@value` as binary string
```ruby
@value = @@generator.generate  # 12-byte binary string
```

**Benefits:**
- Eliminates `unpack('C12')` call on every generation
- Reduces memory: 12 bytes vs 12 integer objects + array overhead
- Direct encoding from binary (no intermediate conversion)

**Trade-off:**
- Field extractors (`pid`, `counter`, etc.) slightly slower
- Acceptable: These are rarely used vs `to_s()`

### 2. Base32 Encoding Optimizations

**A. Pre-compute decode map**
```ruby
# Before: Rebuilds hash on every decode
def decode_hex_map
  Hash[ENCODE_HEX.each_with_index.map { |x, i| [x, i] }]
end

# After: Constant
DECODE_HEX_MAP = Hash[ENCODE_HEX.each_with_index.map { |x, i| [x, i] }].freeze
```

**B. Direct string building**
```ruby
# Before: Array + join
dst = []
dst[0] = ENCODE_HEX[...]
# ... 20 assignments
dst.join('')

# After: Direct string building
dst = String.new(capacity: 20)
dst << ENCODE_HEX[...]
# ... 20 appends
dst.freeze
```

**C. Binary string access**
Use `getbyte(index)` to read from binary `@value` directly instead of array access.

### 3. Method Optimizations

**machine() method:**
```ruby
# Before: Creates intermediate array and strings
def machine
  value[4..6].map(&:chr).join('')
end

# After: Direct substring
def machine
  @value[4, 3]
end
```

**Field extractors:**
```ruby
# Before: Array access
def pid
  (value[7] << 8 | value[8])
end

# After: Binary string access
def pid
  (@value.getbyte(7) << 8 | @value.getbyte(8))
end
```

### 4. Decode Optimizations

- Reduce temporary array allocations in loop
- Use direct byte manipulation where possible
- Pre-allocate result array with correct size

### 5. String Freezing

- Freeze encoded strings to prevent duplication
- Use `String.new(capacity: N)` for pre-sized buffers
- Leverage frozen string literals where applicable

## Expected Performance Improvements

- **Generation + stringification:** 30-50% faster
- **Memory allocations:** 40-60% reduction
- **Decode operations:** 15-20% faster
- **GC pressure:** Significantly reduced

## Backward Compatibility

All public APIs remain unchanged:
- `Xid.new()` - Same behavior
- `to_s()` - Same output format
- `from_string(str)` - Same parsing
- `pid()`, `counter()`, `time()`, `machine()` - Same return values
- Comparison operators - Same behavior
- Thread safety - Maintained

Only internal storage format changes (`@value` representation), which is a private implementation detail.

## Test Coverage

All existing tests will pass:
- ✓ Uniqueness test
- ✓ String round-trip conversion
- ✓ Field extraction validation
- ✓ Go compatibility tests
- ✓ Thread safety test

## Implementation Plan

1. Update `Xid` class to store binary string
2. Optimize `Base32` encoding with constants and direct string building
3. Update field extractors to use `getbyte()`
4. Optimize decode path with constant map
5. Add string freezing optimizations
6. Run full test suite to verify compatibility
7. Run benchmarks to measure improvements

## Risks & Mitigations

**Risk:** Breaking internal behavior other code depends on
**Mitigation:** All public APIs unchanged; comprehensive test coverage

**Risk:** Performance regression on field extraction
**Mitigation:** Acceptable trade-off for primary use case (generate + stringify)

**Risk:** Ruby version compatibility issues
**Mitigation:** Test on Ruby >= 1.9.3 as per gemspec

## Success Criteria

- [ ] All existing tests pass
- [ ] 30%+ improvement in `Xid.new.to_s` benchmark
- [ ] Reduced memory allocations measurable via benchmark
- [ ] No API breaking changes
- [ ] Thread safety maintained
