#!/bin/sh

print_exit() {
    printf '!!! %s\n' "$1"
    exit "$2"
}

test_print() {
    local expected="$1"
    shift 1

    echo ""
    echo "Testing: $@"

    "$@"
    [ $? -ne $expected ] && print_exit 'Failed test!' 1
}

odin build test.odin -out=test || print_exit 'Failed to compile!' 1
printf 'Compiled test.odin!\n'

test_print 0 ./test --string 'a string' --bool --int 999 --uint 999
test_print 2 ./test --int nope --uint 111
test_print 2 ./test --int 111 --uint nope
test_print 2 ./test --string
test_print 2 ./test -sb
test_print 2 ./test -bs
test_print 0 ./test -bs 'a string'
test_print 2 ./test -bcs
test_print 2 ./test --notanarg
test_print 2 ./test

unset print_exit test_print

printf '\nAll tests passed! :)\n'