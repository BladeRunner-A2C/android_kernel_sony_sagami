#!/bin/bash
#
# Compile script for Sony Sagami kernel
# SPDX-FileCopyrightText: Adithya R.

echo_i() { echo -e "\n\033[1;36m==> $1\033[0m\n"; }
echo_w() { echo -e "\033[1;33m $1\033[0m"; }
echo_e() { echo -e "\n\033[1;31m $1\033[0m\n"; }

SECONDS=0 # start builtin bash timer
TC_DIR="$HOME/tc/clang-21.1.8"
AK3_DIR="$HOME/AnyKernel3"

DO_CLEAN=false
REGEN_DEFCONFIG=false
TARGET=

while (( $# > 0 )); do
    case "$1" in
        -c|--clean) DO_CLEAN=true ;;
        -r|--regen) REGEN_DEFCONFIG=true ;;
        *) TARGET="${1}" ;;
    esac
    shift
done

if [ -z "$TARGET" ]; then
    echo_e "Target (device) not specified!"
    exit 1
fi

kernel="out/arch/arm64/boot/Image"
dtb_dir="out/arch/arm64/boot/dts/vendor/qcom"
dtbo_dir="out/arch/arm64/boot/dts/vendor/somc"

ZIPNAME="SentrY-$TARGET-$(date '+%Y%m%d-%H%M').zip"
if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
    head=$(git rev-parse --verify HEAD 2>/dev/null); then
        ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

DEFCONFIG="sagami_defconfig"

##
## Helper functions
##

m() {
    make -j$(nproc) O=out ARCH=arm64 CC="ccache clang" LLVM=1 LLVM_IAS=1 \
        DTC_EXT="$(command -v dtc)" TARGET_PRODUCT=$TARGET "$@" || exit $?
}

build_kernel() {
    echo_i "Building kernel image..."
    m Image 2> >(tee out/error.log >&2)
}

pack_ak3() {
    if [[ -d $AK3_DIR ]]; then
        cp -r $AK3_DIR AnyKernel3
        git -C AnyKernel3 checkout sagami &>/dev/null
    else
        if ! git clone -q https://github.com/BladeRunner-A2C/AnyKernel3 -b sagami --depth=1; then
            echo_w "AnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
            exit 1
        fi
    fi
    cp $kernel AnyKernel3
    echo_i "Copied kernel to AnyKernel3/Image"
    cat $dtb_dir/*.dtb > AnyKernel3/dtb
    echo_i "Copied dtb to AnyKernel3/dtb"
    python3 scripts/dtc/libfdt/mkdtboimg.py create AnyKernel3/dtbo.img --page_size=4096 $dtbo_dir/*.dtbo
    echo_i "Generated dtbo to AnyKernel3/dtbo.img"
    rm -rf out/arch/arm64/boot
    cd AnyKernel3
    zip -r9 ../$ZIPNAME * -x .git README.md *placeholder
    cd ..
    rm -rf AnyKernel3
    echo _i "Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo_i "Zip: $(realpath $ZIPNAME)"
}

upload() {
    echo_i "Uploading..."
    output=$(curl --progress-bar -T "$ZIPNAME" -u :"$PD_API_KEY" https://pixeldrain.com/api/file/ | cat)
    id=$(echo $output | jq -r '.id')
    echo_i "Download URL: https://pixeldrain.com/api/file/$id?download"
}

##
## Main logic starts here
##

export PATH="$TC_DIR/bin:$PATH"

$DO_CLEAN && {
    rm -rf out
    echo_i "Cleaned output directories."
}

$REGEN_DEFCONFIG && {
    echo_i "Regenerating config..."
    m $DEFCONFIG savedefconfig || return
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    echo_i "Successfully regenerated defconfig at '$DEFCONFIG'"
    exit
}

mkdir -p out

echo_i "Generating config..."
m $DEFCONFIG
m ./scripts/kconfig/merge_config.sh $DEFCONFIG vendor/${TARGET}_QGKI.config

build_kernel

if [[ -f $kernel && -d $dtb_dir && -d $dtbo_dir ]]; then
    echo_i "Kernel compiled succesfully! Zipping up..."
    pack_ak3
    upload
else
    echo_e "Compilation failed!"
    exit 1
fi
