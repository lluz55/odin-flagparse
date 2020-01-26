package main

import "core:os"
import "core:fmt"
import "flagparse"

flag_string  := flagparse.track_flag('s', "string", "string value", "string");
flag_bool    := flagparse.track_flag('b', "bool", "bool value", false);
flag_int     := flagparse.track_flag('i', "int", "int value", cast(int) 0);
flag_uint    := flagparse.track_flag('u', "uint", "uint value", cast(uint) 0);

main :: proc() {
    flagparse.parse_all_flags();

    fmt.printf("string: %s\n", flag_string^);
    fmt.printf("bool: %v\n", flag_bool^);
    fmt.printf("int: %d\n", flag_int^);
    fmt.printf("uint: %d\n", flag_uint^);
}
