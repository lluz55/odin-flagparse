package flagparse

import "core:strconv"

@(private)
is_valid_int :: proc(str: string) -> bool {
    if str[0] == '-' do return is_valid_uint(str[1:]);
    else do return is_valid_uint(str);
}

@(private)
is_valid_uint :: proc(str: string) -> bool {
    for s, _ in str {
        switch s {
            case '0'..'9':
                // all good!

            case:
                return false;
        }
    }

    return true;
}

@(private)
is_valid_float :: proc(str: string) -> bool {
    dotcount := 0;

    for s, _ in str {
        switch s {
            case '0'..'9':
                // all good!

            case '.':
                if dotcount == 0 {
                    // all good!
                    dotcount += 1;
                } else {
                    return false;
                }

            case:
                return false;
        }
    }

    return true;
}

@(private)
parse_string_value :: proc(str: string, p: rawptr, type: typeid) {
    // We use strcnv's string parsing methods
    switch type {
        case string:
            newstr := new_clone(str);
            n := cast(^string) p;
            n^ = newstr^;

        case int:
            if !is_valid_int(str) {
                print_exit(2, "Unable to parse int: %s\n", str);
            }

            newint := new(int);
            newint^ = strconv.parse_int(str);

            n := cast(^int) p;
            n^ = newint^;

        case uint:
            if !is_valid_uint(str) {
                print_exit(2, "Unable to parse uint: %s\n", str);
            }

            newuint := new(uint);
            newuint^ = strconv.parse_uint(str);

            n := cast(^uint) p;
            n^ = newuint^;

        case i32:
            if !is_valid_int(str) {
                print_exit(2, "Unable to parse i32: %s\n", str);
            }

            newi32 := new(i32);
            newi32^ = cast(i32) strconv.parse_i64(str);

            n := cast(^i32) p;
            n^ = newi32^;

        case u32:
            if !is_valid_uint(str) {
                print_exit(2, "Unable to parse u32: %s\n", str);
            }

            newu32 := new(u32);
            newu32^ = cast(u32) strconv.parse_u64(str);

            n := cast(^u32) p;
            n^ = newu32^;

        case i64:
            if !is_valid_int(str) {
                print_exit(2, "Unable to parse i64: %s\n", str);
            }

            newi64 := new(i64);
            newi64^ = strconv.parse_i64(str);

            n := cast(^i64) p;
            n^ = newi64^;

        case u64:
            if !is_valid_uint(str) {
                print_exit(2, "Unable to parse u64: %s\n", str);
            }

            newu64 := new(u64);
            newu64^ = strconv.parse_u64(str);

            n := cast(^u64) p;
            n^ = newu64^;

        case rune:
            if len(str) != 1 {
                print_exit(2, "Unable to parse rune: %s\n", str);
            }
            
            newrune := new(rune);
            newrune^ = cast(rune) str[0];

            n := cast(^rune) p;
            n^ = newrune^;

        case f32:
            if !is_valid_float(str) {
                print_exit(2, "Unable to parse f32: %s\n", str);
            }

            newf32 := new(f32);
            newf32^ = strconv.parse_f32(str);

            n := cast(^f32) p;
            n^ = newf32^;

        case f64:
            if !is_valid_float(str) {
                print_exit(2, "Unable to parse f64: %s\n", str);
            }

            newf64 := new(f64);
            newf64^ = strconv.parse_f64(str);

            n := cast(^f64) p;
            n^ = newf64^;

        case:
            print_exit(1, "CRITICAL ERROR: escaped switch statement, unsupported type '%t'\n", type);
    }
}