package argparse

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:unicode/utf8"
import "core:strings"

Arg :: struct {
    key: string,
    desc: string,
    ptr: rawptr,
    type: typeid,
};

ARG_DICT  := make([dynamic]Arg);
VAL_ARRAY := make([dynamic]rawptr);
HAS_RUN   := false;

// TODO: handle not-supported argument value types
// TODO: handle not-provided argument keys
// TODO: improve print strings
// TODO: handle not allowing >=2 args of same string
// TODO: have separate array of argument values so we can free
//       memory of keys and descriptions

__usage_print :: proc() {
    // iterate through ARG_DICT and print
    length := len(ARG_DICT);

    fmt.eprintf("Usage:\n");
    for i := 0; i < length; i += 1 {;
        fmt.eprintf("--%s\t%s\n", ARG_DICT[i].key, ARG_DICT[i].desc);
    }
}

__usage_print_exit :: proc(code: int) {;
    __usage_print();
    os.exit(code);
}

parse_all_args :: proc() {
    parse_args(os.args[1:]);
}

parse_args :: proc(args: []string) {
    length := len(args);
    keys_length := len(ARG_DICT);

    // No arguments supplied or none set to track
    if length == 1 || keys_length == 0 {
        __usage_print_exit(0);
        return;
    }

    // Odd number of arguments supplied (not enough values for keys!)
    else if length % 2 != 0 {
        __usage_print_exit(0);
        return;
        // TODO: check consensus on return codes for failing out due to wrong args
    }

    a: string;
    i, j, k: int;
    for i = 0; i < length; i += 1 {
        a = args[i];

        // Strip any leading hyphens (up to 2!)
        for j = 0; j < 2; j += 1 {
            if a[0] == '-' {
                a = a[1:];
            }
        }

        for k = 0; k < keys_length; k += 1 {
            // Check if key matches
            if a == ARG_DICT[k].key {
                // TODO: add ability to handle bools in future with no arg + just toggle
                __parse_string_value(args[i+1], ARG_DICT[k].ptr, ARG_DICT[k].type);
                i += 1;
                break;
            }
        }
    }

    delete(ARG_DICT);
}

__parse_string_value :: proc(str: string, p: rawptr, type: typeid) {
    // We use strcnv's string parsing methods
    // TODO: handle failed number parsing

    switch type {
        case string:
            newstr := new_clone(str);
            n := cast(^string) p;
            n^ = newstr^;

        case bool:
            result := new(bool);
            ok: bool;

            result^, ok = strconv.parse_bool(str);
            if !ok {
                __usage_print_exit(1);
            }

            n := cast(^bool) p;
            n^ = result^;

        case int:
            i := new(int);
            i^ = strconv.parse_int(str);

            n := cast(^int) p;
            n^ = i^;

        case uint:
            u := new(uint);
            u^ = strconv.parse_uint(str);

            n := cast(^uint) p;
            n^ = u^;

        case i32:
            i := new(i32);
            i^ = i32(strconv.parse_i64(str));
            
            n := cast(^i32) p;
            n^ = i^;

        case u32:
            u := new(u32);
            u^ = u32(strconv.parse_u64(str));
            
            n := cast(^u32) p;
            n^ = u^;

        case i64:
            i := new(i64);
            i^ = strconv.parse_i64(str);

            n := cast(^i64) p;
            n^ = i^;

        case u64:
            u := new(u64);
            u^ = strconv.parse_u64(str);

            n := cast(^u64) p;
            n^ = u^;

        case rune:
            // TODO: improve handling here instead of just taking 0th string index
            r := new(rune);
            r^ = utf8.rune_at_pos(str, 0);

            n := cast(^rune) p;
            n^ = r^;

        case f32:
            f := new(f32);
            f^ = strconv.parse_f32(str);

            n := cast(^f32) p;
            n^ = f^;

        case f64:
            f := new(f64);
            f^ = strconv.parse_f64(str);

            n := cast(^f64) p;
            n^ = f^;

        case:
            fmt.println("Type error for: %t\n", type);
            __usage_print_exit(1);
    }
}

track_arg :: proc(arg: string, descript: string, default: $T) -> ^T {
    // First, create copy of default
    p := new_clone(default);

    // Append this clone ptr to value array
    append(&VAL_ARRAY, cast(^rawptr) p);

    // Create arg struct with rest of data + append
    a := new(Arg);
    a.key = arg;
    a.desc = descript;
    a.ptr = cast(^rawptr) p;
    a.type = T;
    append(&ARG_DICT, a^);

    return cast(^T) p;
}
