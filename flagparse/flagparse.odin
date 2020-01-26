/*
 * TODO:
 * - improve error-ing out with multi-stack character arguments (prioritize wrong / multiple
 *   calls to same argument over non-bool argument not at end
 * - neaten up all of it
 */

package flagparse

import "core:os"

Flag :: struct {
    flag_char:  u8,
    flag_str:   string,
    desc:       string,
    ptr:        rawptr,
    type:       typeid,
};

@(private) FLAGCHAR_MAP: map[u8]^Flag;
@(private) FLAGSTR_MAP:  map[string]^Flag;
@(private) FLAG_ARRAY := make([dynamic]Flag);
@(private) FLAGSTR_MAX := 0;

parse_all_flags :: proc() {
    parse_flags(os.args[1:]);
}

parse_flags :: proc(args: []string) {
    remain := parse_valid_flags(args);
    if len(remain) > 0 {
        __print_exit(2, "Invalid arguments: %s\n", remain);
    }
}

parse_all_valid_flags :: proc() -> []string {
    return parse_valid_flags(os.args[1:]);
}

parse_valid_flags :: proc(args: []string) -> []string {
    length := len(args);
    ret_array := make([dynamic]string);

    // End defers
    defer {
        delete(FLAGCHAR_MAP);
        delete(FLAGSTR_MAP);
    }

    // No arguments supplied or none set to track
    if length == 0 || len(FLAG_ARRAY) == 0 do return ret_array[:];

    // Predefine variables so not constantly allocating new
    flag_ptr: ^Flag;
    f: string;
    f_len, i, j, k: int;
    match_found: bool;

    // Loop through arguments!
    for i = 0; i < length; i += 1 {
        f = args[i];
        f_len = len(f);
        match_found = true;

        // Invalid argument key, exit
        if f_len < 2 || f[0] != '-' {
            append(&ret_array, f);
            continue;
        }

        // Strip leading "-"
        f = f[1:];
        f_len -= 1;

        /*
         * SINGLE CHAR ARGUMENT:
         * assume passed char argument key
         */
        if f_len == 1 {
            // String starts with (and only contains) hyphen, assume empty string argument
            if f[0] == '-' {
                match_found = false;
            }

            // Help char --> print usage exit
            else if f[0] == 'h' do __print_usage_exit(0);

            // Check if char in FLAGCHAR_MAP
            else if f[0] in FLAGCHAR_MAP {
                flag_ptr = FLAGCHAR_MAP[f[0]];

                if flag_ptr.type == bool do __toggle_bool_value(flag_ptr.ptr);
                else {
                    __parse_string_value(args[i+1], flag_ptr.ptr, flag_ptr.type);
                    i += 1;
                }

                delete_key(&FLAGCHAR_MAP, flag_ptr.flag_char);
                delete_key(&FLAGSTR_MAP, flag_ptr.flag_str);
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
            if f[0] != '-' {
                // Iterate through individual chars
                for j = 0; j < f_len; j += 1 {
                    // Help char --> print usage exit
                    if f[j] == 'h' do __print_usage_exit(0);

                    // Check if char in FLAGCHAR_MAP
                    if f[j] in FLAGCHAR_MAP {
                        flag_ptr = FLAGCHAR_MAP[f[j]];

                        if flag_ptr.type == bool do __toggle_bool_value(flag_ptr.ptr);
                        else {
                            if j == f_len - 1 {
                                // Final char in multi-stack is allowed to accept non-bool type argument
                                if i == length - 1 {
                                    // Reached end of argument array, no value supplied
                                    __print_exit(2, "No value supplied for key: -%c | --%s", flag_ptr.flag_char, flag_ptr.flag_str);
                                }

                                __parse_string_value(args[i+1], flag_ptr.ptr, flag_ptr.type);
                                i += 1;
                            } else {
                                __print_exit(2, "Cannot pass value for non-bool argument not at end of character stack: %s\n", f);
                            }
                        }

                        delete_key(&FLAGCHAR_MAP, flag_ptr.flag_char);
                        delete_key(&FLAGSTR_MAP, flag_ptr.flag_str);
                    } else {
                        match_found = false;
                        break;
                    }
                }
            }

            // String starts with hyphen, attempt parse string argument
            else {
                // Strip extra leading "-"
                f = f[1:];

                // Help string --> print usage exit
                if f == "help" do __print_usage_exit(0);

                // Check if string in FLAGSTR_MAP
                if f in FLAGSTR_MAP {
                    flag_ptr = FLAGSTR_MAP[f];

                    if flag_ptr.type == bool do __toggle_bool_value(flag_ptr.ptr);
                    else {
                        __parse_string_value(args[i+1], flag_ptr.ptr, flag_ptr.type);
                        i += 1;
                    }

                    delete_key(&FLAGCHAR_MAP, flag_ptr.flag_char);
                    delete_key(&FLAGSTR_MAP, flag_ptr.flag_str);
                } else {
                    match_found = false;
                }
            }
        }

        // Append non-match to return array
        if !match_found do append(&ret_array, f);
    }

    return ret_array[:];
}

@(private)
__toggle_bool_value :: proc(p: rawptr) {
    n := cast(^bool) p;
    n^ = ! n^;
}

track_flag :: proc($flag_char: u8, $flag_str, $desc: string, $default: $T) -> ^T {
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

    // COMPILE CHECK: at least valid char and string keys
    #assert(u8(32) <= flag_char && flag_char <= u8(136) && len(flag_str) > 1);
    #assert(flag_char != '-' && flag_str[0] != '-');

    // COMPILE CHECK: no overlap with built-in help argument
    #assert(flag_char != 'h' && flag_str != "help")

    // Check this argument isn't already in array
    if flag_char in FLAGCHAR_MAP || flag_str in FLAGSTR_MAP {
        __print_exit(1, "ERROR: multiple arguments with same key\n");
    }

    // Create copy of default
    p := new_clone(default);

    // Create Arg struct with data + append
    f := new(Flag);
    f.flag_char = flag_char;
    f.flag_str  = flag_str;
    f.desc      = desc;
    f.ptr       = cast(^rawptr) p;
    f.type      = T;
    append(&FLAG_ARRAY, f^);

    // Map keys --> value
    FLAGCHAR_MAP[flag_char] = f;
    FLAGSTR_MAP[flag_str]  = f;

    // If longest, store new max flag_str length
    length := len(flag_str);
    if length > FLAGSTR_MAX do FLAGSTR_MAX = length;

    return cast(^T) p;
}
