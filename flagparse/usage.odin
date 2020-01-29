package flagparse

import "core:os"
import "core:fmt"

@(private)
__print_usage_exit :: proc(code: int) {
    print_usage();
    os.exit(code);
}

@(private)
__print_exit :: proc(code: int, format: string, args: ..any) {
    fmt.eprintf(format, ..args);
    os.exit(code);
}

@(private)
__print_flag :: proc(key_chr: u8, key_str, desc: string, space_count: int) {
    // Initially print key_chr and key_str
    fmt.eprintf(" -%c | --%s ", key_chr, key_str);

    // Print requested tab_count
    for i := 0; i < space_count + 1; i += 1 {
        fmt.eprintf(" ");
    }

    // Print description
    fmt.eprintf(": %s\n", desc);
}

print_usage :: proc() {
    if USAGE_STRING == "" do fmt.eprintf("Usage:\n");
    else do fmt.eprintf(USAGE_STRING);

    space_count := FLAGSTR_MAX - 4;
    __print_flag('h', "help", "print usage", space_count);

    for i := 0; i < len(FLAG_ARRAY); i += 1 {
        space_count = FLAGSTR_MAX - len(FLAG_ARRAY[i].flag_str);
        __print_flag(FLAG_ARRAY[i].flag_char, FLAG_ARRAY[i].flag_str, FLAG_ARRAY[i].desc, space_count);
    }
}