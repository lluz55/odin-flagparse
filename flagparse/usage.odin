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
__print_flag :: proc(key_chr: u8, key_str, desc: string, tab_count: int) {
    // Initially print key_chr and key_str
    fmt.eprintf("-%c | --%s", key_chr, key_str);

    // Print requested tab_count
    for i := 0; i < tab_count + 1; i += 1 {
        fmt.eprintf("\t");
    }

    // Print description
    fmt.eprintf("%s\n", desc);
}

print_usage :: proc() {
    fmt.eprintf("Usage:\n");

    tabcount := (FLAGSTR_MAX - 4) / 8;
    __print_flag('h', "help", "print usage", tabcount);

    for i := 0; i < len(FLAG_ARRAY); i += 1 {
        tabcount = (FLAGSTR_MAX - len(FLAG_ARRAY[i].flag_str)) / 8;
        __print_flag(FLAG_ARRAY[i].flag_char, FLAG_ARRAY[i].flag_str, FLAG_ARRAY[i].desc, tabcount);
    }
}