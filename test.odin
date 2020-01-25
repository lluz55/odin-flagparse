package main

import "core:os"
import "core:fmt"
import "argparse"

arg_string  := argparse.track_arg("s", "string", "string value", "string");
arg_bool    := argparse.track_arg("b", "bool", "bool value", false);
arg_int     := argparse.track_arg("i", "int", "int value", cast(int) 0);
arg_uint    := argparse.track_arg("u", "uint", "uint value", cast(uint) 0);

main :: proc() {
    argparse.parse_all_args();
    fmt.printf("Arg parse test!\n");
    fmt.printf("string: %s\n", arg_string^);
    fmt.printf("bool: %v\n", arg_bool^);
    fmt.printf("int: %d\n", arg_int^);
    fmt.printf("uint: %d\n", arg_uint^);
}
