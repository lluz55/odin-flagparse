# Odin argument parsing library

## Usage

`track_arg :: proc(key_char, key_string, description: string, default: $T) -> ^T`

A pointer to the value is returned from `track_arg(...)`, and will contain either the default
value or the parsed passed (heh) value. The underlying data type is set by the type of the default
value, so specific casting of the default value can be used to ensure specific parsing.

Supported types:
- string
- bool
- int
- uint
- i32
- u32
- i64
- u64
- rune
- f32
- f64

Parsing these values is acheived with any of the following:
- `parse_valid_args :: proc(args: []string) -> []string` which parses a supplied string array and returns
invalid arguments
- `parse_all_valid_args :: proc() -> []string` which performs `parse_valid_args(os.args[1:])` and returns
invalid arguments
- `parse_args :: proc(args: []string)` which performs `parse_valid_args(args)` but prints usage string and
exits if any invalid arguments are returned
- `parse_all_args :: proc()` which performs `parse_args(os.args[1:])` and prints usage then exits for
invalid arguments

Example in `test.odin`