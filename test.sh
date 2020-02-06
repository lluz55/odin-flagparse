#!/bin/sh

print_exit() {
    printf '%s\n' "$1"
    exit $2
}

odin build test.odin || print_exit 'Failed to compile!\n' 1
printf 'Compiled test.odin!\n'

printf '\nTesting values: string="a string" bool=true int=999 uint=999\n'
./test --string 'a string' --bool --int 999 --uint 999

printf '\nTesting values: int=nope uint=111\n'
./test --int nope --uint 111

printf '\nTesting values: int=111 uint=nope\n'
./test --int 111 --uint nope

printf '\nTesting zero arg usage print:\n'
./test

unset print_exit