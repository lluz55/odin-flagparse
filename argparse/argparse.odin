/*
 * TODO:
 * - improve usage print strings
 * - add maximum string length / ability to set max string length (?)
 * - improve arg key check speed
*/

package argparse

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"
import "core:strings"

Arg :: struct {
    key_chr:    string,
    key_str:    string,
    desc:       string,
    ptr:        rawptr,
    type:       typeid,
};

ARG_ARRAY := make([dynamic]Arg);    // argument structs, deleted at end of parse_args()
STR_MAX   := 255;

__print_usage_exit :: proc(code: int) {
    print_usage();
    os.exit(code);
}

__print_exit :: proc(code: int, format: string, args: ..any) {
    fmt.eprintf(format, ..args);
    os.exit(code);
}

__print_arg_key :: proc(key_chr, key_str, desc: string) {
    fmt.eprintf("-%s|--%s\t%s\n", key_chr, key_str, desc);
}

print_usage :: proc() {
    // Iterate through ARG_ARRAY and print
    length := len(ARG_ARRAY);

    fmt.eprintf("Usage:\n");
    __print_arg_key("h", "help", "print usage");
    for i := 0; i < length; i += 1 {
        __print_arg_key(ARG_ARRAY[i].key_chr, ARG_ARRAY[i].key_str, ARG_ARRAY[i].desc);
    }
}

parse_all_args :: proc() {
    parse_args(os.args[1:]);
}

parse_args :: proc(args: []string) {
    remain := parse_valid_args(args);
    if len(remain) > 0 {
        __print_exit(2, "Invalid arguments: %s\n", remain);
    }
}

parse_all_valid_args :: proc() -> []string {
    return parse_valid_args(os.args[1:]);
}

parse_valid_args :: proc(args: []string) -> []string {
    length := len(args);
    keys_length := len(ARG_ARRAY);
    ret_array := make([dynamic]string);

    // No arguments supplied or none set to track
    if length == 0 || keys_length == 0 do return ret_array[:];

    // Predefine variables so not constantly allocating new
    a: string;
    a_len, i, j, k: int;
    match_found: bool;

    // Loop through arguments!
    for i = 0; i < length; i += 1 {
        a = args[i];
        a_len = len(a);

        // Invalid argument key, exit
        if a_len < 2 || a[0] != '-' {
            append(&ret_array, a);
            continue;
        }

        // a_len == 2 --> assume passed char argument key
        if a_len == 2 {
            if a[1] == '-' {
                append(&ret_array, a);
                continue;
            }

            // Strip leading "-"            
            a = a[1:];

            // Check for "h" help request
            if a == "h" do __print_usage_exit(0);
        }

        // a_len > 2 --> assume passed string argument key
        else {
            if a[1] != '-' {
                append(&ret_array, a);
                continue;
            }

            // Strip leading "--"
            a = a[2:];

            // Check for "help" help request
            if a == "help" do __print_usage_exit(0);
        }

        match_found = true;
        for k = 0; k < keys_length; k += 1 {
            if a == ARG_ARRAY[k].key_chr || a == ARG_ARRAY[k].key_str {
                if ARG_ARRAY[k].type == bool {
                    __toggle_bool_value(ARG_ARRAY[k].ptr);
                } else {
                    __parse_string_value(args[i+1], ARG_ARRAY[k].ptr, ARG_ARRAY[k].type);
                    i += 1;
                }

                match_found = true;
                break;
            }
        }

        // Append non-match to return array
        if !match_found do append(&ret_array, a);
    }

    return ret_array[:];
}

__toggle_bool_value :: proc(p: rawptr) {
    n := cast(^bool) p;
    n^ = ! n^;
}

__is_zero_int :: proc(str: string) -> bool {
    for s, i in str {
        switch s {
            case '0':
                continue;

            case:
                return false;
        }
    }

    return true;
}

__is_zero_float :: proc(str: string) -> bool {
    dotcount := 0;
    for s, i in str {
        switch s {
            case '0':
                continue;

            case '.':
                dotcount += 1;
                continue;

            case:
                return false;
        }
    }

    return dotcount <= 1;
}

__parse_string_value :: proc(str: string, p: rawptr, type: typeid) {
    // We use strcnv's string parsing methods
    switch type {
        case string:
            newstr := new_clone(str);
            ok := true;

            // Assume always fine for strings
            if !ok { __print_usage_exit(2); };

            n := cast(^string) p;
            n^ = newstr^;

        case int:
            newint := new(int);

            newint^ = strconv.parse_int(str);
            if newint^ == 0 && !__is_zero_int(str) {
                __print_usage_exit(2);
            }

            n := cast(^int) p;
            n^ = newint^;

        case uint:
            newuint := new(uint);

            newuint^ = strconv.parse_uint(str);
            if newuint^ == 0 && !__is_zero_int(str) {
                __print_usage_exit(2);
            }

            n := cast(^uint) p;
            n^ = newuint^;

        case i32:
            newi32 := new(i32);

            newi32^ = cast(i32) strconv.parse_i64(str);
            if newi32^ == 0 && !__is_zero_int(str) {
                __print_usage_exit(2);
            }

            n := cast(^i32) p;
            n^ = newi32^;

        case u32:
            newu32 := new(u32);

            newu32^ = cast(u32) strconv.parse_u64(str);
            if newu32^ == 0 && !__is_zero_int(str) {
                __print_usage_exit(2);
            }

            n := cast(^u32) p;
            n^ = newu32^;

        case i64:
            newi64 := new(i64);

            newi64^ = strconv.parse_i64(str);
            if newi64^ == 0 && !__is_zero_int(str) {
                __print_usage_exit(2);
            }

            n := cast(^i64) p;
            n^ = newi64^;

        case u64:
            newu64 := new(u64);

            newu64^ = strconv.parse_u64(str);
            if newu64^ == 0 && !__is_zero_int(str) {
                __print_usage_exit(2);
            }

            n := cast(^u64) p;
            n^ = newu64^;

        case rune:
            if len(str) != 1 {
                __print_usage_exit(2);
            }
            
            newrune := new(rune);
            newrune^ = cast(rune) str[0];

            n := cast(^rune) p;
            n^ = newrune^;

        case f32:
            newf32 := new(f32);

            newf32^ = strconv.parse_f32(str);
            if newf32^ == 0.0 && !__is_zero_float(str) {
                __print_usage_exit(2);
            }

            n := cast(^f32) p;
            n^ = newf32^;

        case f64:
            newf64 := new(f64);

            newf64^ = strconv.parse_f64(str);
            if newf64^ == 0.0 && !__is_zero_float(str) {
                __print_usage_exit(2);
            }

            n := cast(^f64) p;
            n^ = newf64^;

        case:
            __print_exit(1, "CRITICAL ERROR: escaped switch statement, unsupported type '%t'\n", type);
    }
}

track_arg :: proc($key_chr, $key_str, $desc: string, default: $T) -> ^T {
    // COMPILE CHECK: only compatible type passed
    #assert(
        T == string ||
        T == bool   ||
        T == int    ||
        T == uint   ||
        T == i32    ||
        T == u32    ||
        T == i64    ||
        T == u64    ||
        T == rune   ||
        T == f32    ||
        T == f64,
    );

    // COMPILE CHECK: at least one valid char / string key
    #assert( (len(key_chr) == 1 && key_chr[0] != '-') || (len(key_str) > 0 && key_str[0] != '-') );

    // Check this argument isn't already in array
    for arg, _ in ARG_ARRAY {
        if arg.key_chr == key_chr || arg.key_str == key_str {
            __print_exit(1, "ERROR: multiple arguments with same key\n");
        }
    }

    // Create copy of default
    p := new_clone(default);

    // Create arg struct with rest of data + append
    a := new(Arg);
    a.key_chr = key_chr;
    a.key_str = key_str;
    a.desc    = desc;
    a.ptr     = cast(^rawptr) p;
    a.type    = T;
    append(&ARG_ARRAY, a^);

    return cast(^T) p;
}
