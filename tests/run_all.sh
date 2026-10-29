#!/bin/bash

if [ -t 1 ]; then
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    CYAN=''
    NC=''
fi

echo -e "${CYAN}TAP version 13${NC}"

OVMF_CODE_PATH=${1:-/usr/share/edk2/ovmf/OVMF_CODE.fd}
OVMF_VARS_TEMPLATE_PATH=${2:-/usr/share/edk2/ovmf/OVMF_VARS.fd}
TEST_IMAGE=$3
ROOT_PASSWORD=$4

VERBOSE=0
if [[ "$5" == "-v" || "$5" == "--verbose" ]]; then
    VERBOSE=1
    set -x
fi
export VERBOSE

TAP_COUNTER_FILE=$(mktemp)
export TAP_COUNTER_FILE

echo "0" > "$TAP_COUNTER_FILE"

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
FAILURES=0

if [ -z "$TEST_IMAGE" ]; then
    IMAGE_URL=https://download.fedoraproject.org/pub/fedora/linux/releases/44/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2
    TEST_IMAGE=/tmp/test.qcow2
    ROOT_PASSWORD=12345

    if [ ! -f $TEST_IMAGE ]; then
        curl -L $IMAGE_URL -o $TEST_IMAGE
        # export LIBGUESTFS_BACKEND=direct
        # export LIBGUESTFS_PATH=$PWD/fixed-appliance
        virt-customize -a $TEST_IMAGE --root-password password:$ROOT_PASSWORD
    fi
fi

for test_file in "$TEST_DIR"/test_*.sh; do
    if [[ "$test_file" == *"test_helper.sh" ]]; then
        continue
    fi

    if ! bash "$test_file" "$TEST_IMAGE" "$ROOT_PASSWORD" "$OVMF_VARS_TEMPLATE_PATH" "$OVMF_CODE_PATH"; then
        FAILURES=$((FAILURES + 1))
    fi
done

TOTAL_TESTS=$(cat "$TAP_COUNTER_FILE")
if [ "$TOTAL_TESTS" -gt 0 ]; then
    echo -e "${CYAN}1..$TOTAL_TESTS${NC}"
fi

rm -f "$TAP_COUNTER_FILE"
exit $((FAILURES > 0 ? 1 : 0))
