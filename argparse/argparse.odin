/*
 * TODO:
 * - improve usage print strings
 * - add ability to handle bools in future with no arg + just toggle
 * - add maximum string length / ability to set max string length (?)
*/

package argparse

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"
import "core:strings"

Arg :: struct {
    key:    string,
    desc:   string,
    ptr:    rawptr,
    type:   typeid,
};

ARG_ARRAY := make([dynamic]Arg);    // argument structs, deleted at end of parse_args()
VAL_ARRAY := make([dynamic]rawptr); // raw argument value pointers, not deleted

__print_usage_exit :: proc(code: int) {
    print_usage();
    os.exit(code);
}

__print_exit :: proc(code: int, format: string, args: ..any) {
    fmt.eprintf(format, ..args);
    os.exit(code);
}

print_usage :: proc() {
    // Iterate through ARG_ARRAY and print
    length := len(ARG_ARRAY);

    fmt.eprintf("Usage:\n");
    for i := 0; i < length; i += 1 {
        fmt.eprintf("--%s\t%s\n", ARG_ARRAY[i].key, ARG_ARRAY[i].desc);
    }
}

parse_all_args :: proc() {
    parse_args(os.args[1:]);
}

parse_args :: proc(args: []string) {
    length := len(args);
    keys_length := len(ARG_ARRAY);

    // No arguments supplied or none set to track
    if length == 1 || keys_length == 0 {
        __print_usage_exit(0);
    }

    // Odd number of arguments supplied (not enough values for keys!)
    else if length % 2 != 0 {
        __print_usage_exit(2);
    }

    a: string;
    i, j, k: int;
    match_found: bool;    
    for i = 0; i < length; i += 1 {
        a = args[i];

        // Strip any leading hyphens (up to 2!)
        for j = 0; j < 2; j += 1 {
            if a[0] == '-' {
                a = a[1:];
            }
        }

        match_found = false;
        for k = 0; k < keys_length; k += 1 {
            // Always response to user's requests for help :']
            if a == "help" {
                __print_usage_exit(0);
            }

            // Check if key matches
            else if a == ARG_ARRAY[k].key {
                __parse_string_value(args[i+1], ARG_ARRAY[k].ptr, ARG_ARRAY[k].type);
                match_found = true;
                i += 1;
                break;
            }
        }

        if !match_found {
            __print_usage_exit(2);
        }
    }

    delete(ARG_ARRAY);
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

        case bool:
            newbool := new(bool);
            ok: bool;

            newbool^, ok = strconv.parse_bool(str);
            if !ok { __print_usage_exit(2); };

            n := cast(^bool) p;
            n^ = newbool^;

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

track_arg :: proc(key: string, desc: string, default: $T) -> ^T {
    // COMPILE_TIME_CHECKS
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

    // Check this argument isn't already in array
    for arg, _ in ARG_ARRAY {
        if arg.key == key {
            __print_exit(1, "ERROR: multiple arguments with same key '%s'\n", key);
        }
    }

    // First, create copy of default
    p := new_clone(default);

    // Append this clone ptr to value array
    append(&VAL_ARRAY, cast(^rawptr) p);

    // Create arg struct with rest of data + append
    a := new(Arg);
    a.key   = key;
    a.desc  = desc;
    a.ptr   = cast(^rawptr) p;
    a.type  = T;
    append(&ARG_ARRAY, a^);

    return cast(^T) p;
}
