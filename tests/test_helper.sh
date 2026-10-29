#!/bin/bash

if [ -z "$TAP_COUNTER_FILE" ]; then
    export TAP_COUNTER_FILE
    TAP_COUNTER_FILE=$(mktemp)
    echo "0" > "$TAP_COUNTER_FILE"
fi

if [ -z "$TAP_FAILURE_FILE" ]; then
    export TAP_FAILURE_FILE
    TAP_FAILURE_FILE=$(mktemp)
    echo "0" > "$TAP_FAILURE_FILE"
fi

if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    NC=''
fi

if [ "$VERBOSE" -eq 1 ]; then
    set -x
fi

assert_contains() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    local count
    count=$(cat "$TAP_COUNTER_FILE")
    count=$((count + 1))
    echo "$count" > "$TAP_COUNTER_FILE"

    if echo "$actual" | grep --quiet "$expected"; then
        echo -e "${GREEN}ok $count - $message${NC}"
        return 0
    else
        echo -e "${RED}not ok $count - $message${NC}"

        if [ "$VERBOSE" -eq 1 ]; then
            echo -e "${YELLOW}#   Failed test: $message${NC}"
            echo -e "${YELLOW}#   Expected: '$expected'${NC}"
            echo -e "${YELLOW}#   Actual:   '$actual'${NC}"
        fi

        echo "1" > "$TAP_FAILURE_FILE"
        return 1
    fi
}

assert_not_contains() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    local count
    count=$(cat "$TAP_COUNTER_FILE")
    count=$((count + 1))
    echo "$count" > "$TAP_COUNTER_FILE"

    if ! echo "$actual" | grep --quiet "$expected"; then
        echo -e "${GREEN}ok $count - $message${NC}"
        return 0
    else
        echo -e "${RED}not ok $count - $message${NC}"

        if [ "$VERBOSE" -eq 1 ]; then
            echo -e "${YELLOW}#   Failed test: $message${NC}"
            echo -e "${YELLOW}#   Not Expected: '$expected'${NC}"
            echo -e "${YELLOW}#   Actual:   '$actual'${NC}"
        fi

        echo "1" > "$TAP_FAILURE_FILE"
        return 1
    fi
}
