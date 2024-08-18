#!/bin/bash
# Copyright (C) 2021 Intel Corporation.
# SPDX-License-Identifier: BSD-3-Clause

set -e

branch=""
secureboot=""
image_size=4

while getopts "hsb:SI:" opt
do
    case "${opt}" in
        h)
            echo "Usage: $0 [-b branch] [-I image_size] [-S]"
            exit 0
            ;;
        b)
            branch=${OPTARG}
            ;;
        S)
            secureboot=yes
            ;;
        I)
            image_size=${OPTARG}
            ;;
        *)
            echo "Invalid option: -${OPTARG}"
            exit 1
            ;;
    esac
done

if [ ! -d edk2 ]; then
    git clone https://github.com/tianocore/edk2.git
    cd edk2
    if [ -n "$branch" ]; then
        git checkout "$branch"
    fi
    git submodule update --init
    cd ..
fi

cd edk2

source edksetup.sh

sed -i "s:^ACTIVE_PLATFORM\s*=\s*\w*/\w*\.dsc*:ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgX64.dsc:g" Conf/target.txt
sed -i "s:^TARGET_ARCH\s*=\s*\w*:TARGET_ARCH           = X64:g" Conf/target.txt
sed -i "s:^TOOL_CHAIN_TAG\s*=\s*\w*:TOOL_CHAIN_TAG        = GCC5:g" Conf/target.txt

OVMF_FLAGS="-DNETWORK_IP6_ENABLE -DNETWORK_HTTP_BOOT_ENABLE -DNETWORK_TLS_ENABLE"
OVMF_FLAGS="$OVMF_FLAGS -DFD_SIZE_${image_size}MB"

if [ -n "$secureboot" ]; then
    OVMF_FLAGS="$OVMF_FLAGS -DSECURE_BOOT_ENABLE -DSMM_REQUIRE -DEXCLUDE_SHELL_FROM_FD -DTPM_ENABLE"
    OVMF_FLAGS="$OVMF_FLAGS -p OvmfPkg/OvmfPkgIa32X64.dsc"
else
    OVMF_FLAGS="$OVMF_FLAGS -p OvmfPkg/OvmfPkgX64.dsc"
fi

make -C BaseTools
build $OVMF_FLAGS

echo "Build complete. OVMF.fd should be available in Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd"