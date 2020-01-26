/*
 * TODO:
 * - improve arg key check speed (remove elements from array / map?)
 * - improve error-ing out with multi-stack character arguments (prioritize wrong / multiple
 *   calls to same argument over non-bool argument not at end
 * - unspaghettify multi-character stack arguments...
 * - neaten up all of it
 * - fix usage print tab spacing
 * - fix issues with empty key_chr or key_str
 */

package argparse

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
__print_arg_key :: proc(key_chr: u8, key_str, desc: string, tab_count: int) {
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

    tabcount := (KEYSTR_MAX - 4) / 8;
    __print_arg_key('h', "help", "print usage", tabcount);

    for i := 0; i < len(ARG_ARRAY); i += 1 {
        tabcount = (KEYSTR_MAX - len(ARG_ARRAY[i].key_str)) / 8;
        __print_arg_key(ARG_ARRAY[i].key_chr, ARG_ARRAY[i].key_str, ARG_ARRAY[i].desc, tabcount);
    }
}