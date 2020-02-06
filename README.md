# Odin flag parsing library

## Coding Usage

`track_flag :: proc(flag_char: u8, flag_string, description: string, default: $T) -> ^T`

A pointer to the value is returned from `track_flag(...)`, and will contain either the default
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

Duplicate character or string flags are strictly not allowed. Character 'h' and string "help" are
reserved for argparse's built-in usage printing.

Parsing these values is acheived with any of the following:
- `parse_valid_flags :: proc(args: []string) -> []string` which parses a supplied string array and returns
invalid arguments
- `parse_all_valid_flags :: proc() -> []string` which performs `parse_valid_flags(os.args[1:])` and returns
invalid arguments
- `parse_flags :: proc(args: []string)` which performs `parse_valid_flags(args)` but prints usage string and
exits if any invalid arguments are returned
- `parse_all_flags :: proc()` which performs `parse_flags(os.args[1:])` and prints usage then exits for
invalid arguments

Set the usage string printed before the table of flags and their descriptions with:
`import "flagparse"

flagparse.USAGE_STRING = "This is the new usage string!\n";
`

Set the behaviour of calling the compiled result with zero args:
`import "flagparse"
...
flagparse.ZERO_ARG_PRINT = true;  // to print usage when no args supplied
flagparse.ZERO_ARG_PRINT = false; // to not do this
`

Example in `test.odin`
