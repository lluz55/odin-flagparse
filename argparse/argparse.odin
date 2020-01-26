/*
 * TODO:
 * - improve error-ing out with multi-stack character arguments (prioritize wrong / multiple
 *   calls to same argument over non-bool argument not at end
 * - neaten up all of it
 */

package argparse

import "core:os"

Arg :: struct {
    key_chr:    u8,
    key_str:    string,
    desc:       string,
    ptr:        rawptr,
    type:       typeid,
};

@(private) KEYCHR_MAP:   map[u8]^Arg;
@(private) KEYSTR_MAP:   map[string]^Arg;
@(private) ARG_ARRAY :=  make([dynamic]Arg);
@(private) KEYSTR_MAX := 0;

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

    // End defers
    defer {
        delete(KEYCHR_MAP);
        delete(KEYSTR_MAP);
    }

    // No arguments supplied or none set to track
    if length == 0 || keys_length == 0 do return ret_array[:];

    // Predefine variables so not constantly allocating new
    arg_ptr: ^Arg;
    a: string;
    a_len, i, j, k: int;
    match_found := true;;

    // Loop through arguments!
    for i = 0; i < length; i += 1 {
        a = args[i];
        a_len = len(a);

        // Invalid argument key, exit
        if a_len < 2 || a[0] != '-' {
            append(&ret_array, a);
            continue;
        }

        // Strip leading "-"
        a = a[1:];
        a_len -= 1;

        /*
         * SINGLE CHAR ARGUMENT:
         * assume passed char argument key
         */
        if a_len == 1 {
            // String starts with (and only contains) hyphen, assume empty string argument
            if a[0] == '-' {
                match_found = false;
            }

            // Help char --> print usage exit
            else if a[0] == 'h' do __print_usage_exit(0);

            // Check if char in KEYCHR_MAP
            else if a[0] in KEYCHR_MAP {
                arg_ptr = KEYCHR_MAP[a[0]];

                if arg_ptr.type == bool do __toggle_bool_value(arg_ptr.ptr);
                else {
                    __parse_string_value(args[i+1], arg_ptr.ptr, arg_ptr.type);
                    i += 1;
                }

                delete_key(&KEYCHR_MAP, arg_ptr.key_chr);
                delete_key(&KEYSTR_MAP, arg_ptr.key_str);
            }

            // Valid char but no match
            else {
                match_found = false;
            }
        }

        /*
         * MULTI CHAR ARGUMENT:
         * assume passed multi-stack char or string argument
         */ 
        else {
            // String does not start with hyphen, attempt parse multi-stack char argument
            if a[0] != '-' {
                // Iterate through individual chars
                for j = 0; j < a_len; j += 1 {
                    // Help char --> print usage exit
                    if a[j] == 'h' do __print_usage_exit(0);

                    // Check if char in KEYCHR_MAP
                    if a[j] in KEYCHR_MAP {
                        arg_ptr = KEYCHR_MAP[a[j]];

                        if arg_ptr.type == bool do __toggle_bool_value(arg_ptr.ptr);
                        else {
                            if j == a_len - 1 {
                                // Final char in multi-stack is allowed to accept non-bool type argument
                                if i == length - 1 {
                                    // Reached end of argument array, no value supplied
                                    __print_exit(2, "No value supplied for key: -%c | --%s", arg_ptr.key_chr, arg_ptr.key_str);
                                }

                                __parse_string_value(args[i+1], arg_ptr.ptr, arg_ptr.type);
                                i += 1;
                            } else {
                                __print_exit(2, "Cannot pass value for non-bool argument not at end of character stack: %s\n", a);
                            }
                        }

                        delete_key(&KEYCHR_MAP, arg_ptr.key_chr);
                        delete_key(&KEYSTR_MAP, arg_ptr.key_str);
                    } else {
                        match_found = false;
                        break;
                    }
                }
            }

            // String starts with hyphen, attempt parse string argument
            else {
                // Strip extra leading "-"
                a = a[1:];

                // Help string --> print usage exit
                if a == "help" do __print_usage_exit(0);

                // Check if string in KEYSTR_MAP
                if a in KEYSTR_MAP {
                    arg_ptr = KEYSTR_MAP[a];

                    if arg_ptr.type == bool do __toggle_bool_value(arg_ptr.ptr);
                    else {
                        __parse_string_value(args[i+1], arg_ptr.ptr, arg_ptr.type);
                        i += 1;
                    }

                    delete_key(&KEYCHR_MAP, arg_ptr.key_chr);
                    delete_key(&KEYSTR_MAP, arg_ptr.key_str);
                } else {
                    match_found = false;
                }
            }
        }

        // Append non-match to return array
        if !match_found do append(&ret_array, a);
    }

    return ret_array[:];
}

@(private)
__toggle_bool_value :: proc(p: rawptr) {
    n := cast(^bool) p;
    n^ = ! n^;
}

track_arg :: proc($key_chr: u8, $key_str, $desc: string, $default: $T) -> ^T {
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
    #assert(len(key_str) > 1);
    #assert(key_chr != '-' && key_str[0] != '-');

    // COMPILE CHECK: no overlap with built-in help argument
    #assert(key_chr != 'h' && key_str != "help")

    // Check this argument isn't already in array
    for arg, _ in ARG_ARRAY {
        if arg.key_chr == key_chr || arg.key_str == key_str {
            __print_exit(1, "ERROR: multiple arguments with same key\n");
        }
    }

    // Create copy of default
    p := new_clone(default);

    // Create Arg struct with data + append
    a := new(Arg);
    a.key_chr = key_chr;
    a.key_str = key_str;
    a.desc    = desc;
    a.ptr     = cast(^rawptr) p;
    a.type    = T;
    append(&ARG_ARRAY, a^);

    // Map keys --> value
    KEYCHR_MAP[key_chr] = a;
    KEYSTR_MAP[key_str] = a;

    // If longest, store new max key_str length
    length := len(key_str);
    if length > KEYSTR_MAX do KEYSTR_MAX = length;

    return cast(^T) p;
}
