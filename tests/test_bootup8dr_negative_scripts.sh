#!/bin/bash

source tests/test_helper.sh
source tests/qemu_test_lib.sh

TEST_IMAGE=$1
ROOT_PASSWORD=$2
OVMF_VARS_TEMPLATE_PATH=$3
OVMF_CODE=$4

IMAGE=/tmp/bootupd8r_negative_test.qcow2
OVMF_VARS=/tmp/bootupd8r_negative_VARS.fd

if [ ! -f $IMAGE ]; then
        cp "$TEST_IMAGE" $IMAGE
fi

if [ ! -f $OVMF_VARS ]; then
        cp "$OVMF_VARS_TEMPLATE_PATH" $OVMF_VARS
        chmod 666 $OVMF_VARS
fi

machine=$(qemu_test_launch -m 2048 \
            -machine q35,smm=on \
            -smp 2 \
            -hda $IMAGE \
            -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
            -drive if=pflash,format=raw,readonly=off,file=$OVMF_VARS \
            -virtfs local,path="$PWD",mount_tag=my_shared_files,security_model=mapped-xattr,id=hdshare \
            -nographic \
            -serial null \
)

qemu_test_login "$machine" "root" "$ROOT_PASSWORD"
qemu_test_wait_for "$machine" "root@"

qemu_test_run_command "$machine" "mkdir -p /usr/lib/bootloader"

qemu_test_run_command "$machine" "mkdir -p /mnt/shared"

qemu_test_run_command "$machine" "mount -t 9p -o trans=virtio,version=9p2000.L my_shared_files /mnt/shared"

qemu_test_run_command "$machine" "cd /mnt/shared"

qemu_test_run_command "$machine" "export PATH=\$PATH:/mnt/shared"

qemu_test_run_command "$machine" "bootupd8r create_boot_path"

qemu_test_run_command "$machine" "clear"
qemu_test_run_command "$machine" "efibootmgr | grep EFI_NEW | grep -o \"_new\""

assert_contains "new" "$(qemu_test_read "$machine")" "Negative: EFI entry has been created successfully"

qemu_test_run_command "$machine" "clear"
qemu_test_run_command "$machine" "efibootmgr | grep EFI_NEW | cut -d' ' -f1 | grep -o \"[0-9]*\""

boot_number=$(qemu_test_read "$machine" | tail -n 3 | head -n 1)
qemu_test_run_command "$machine" "bootupd8r install_bootloader /boot/efi/EFI /boot/efi/EFI_NEW"

qemu_test_run_command "$machine" "clear"
qemu_test_run_command "$machine" "efibootmgr | grep BootNext | cut -d' ' -f2"

assert_contains "$boot_number" "$(qemu_test_read "$machine")" "Negative: BootNext has been set successfully"

qemu_test_run_command "$machine" "rm -f /boot/efi/EFI_NEW/fedora/shimx64.efi"

qemu_test_run_command "$machine" "reboot"

qemu_test_login "$machine" "root" "12345"
qemu_test_wait_for "$machine" "root@"

qemu_test_run_command "$machine" "clear"
qemu_test_run_command "$machine" "efibootmgr | grep BootCurrent | cut -d' ' -f2"

assert_not_contains "$boot_number" "$(qemu_test_read "$machine")" "Negative: BootNext not Booted successfully"

qemu_test_quit "$machine"
