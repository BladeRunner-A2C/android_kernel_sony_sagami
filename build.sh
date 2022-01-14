#!/bin/bash
#
# Compile script for Sony Sagami kernel
# SPDX-FileCopyrightText: Adithya R.

SECONDS=0 # start builtin bash timer
TC_DIR="$HOME/tc/clang-r563880"
AK3_DIR="$HOME/AnyKernel3"

DO_CLEAN=false
REGEN_DEFCONFIG=false
TARGET=pdx215 # default

while (( $# > 0 )); do
    case "$1" in
        -c|--clean) DO_CLEAN=true ;;
        -r|--regen) REGEN_DEFCONFIG=true ;;
        *) TARGET="${1}" ;;
    esac
    shift
done

ZIPNAME="SentrY-$TARGET-$(date '+%Y%m%d-%H%M').zip"
if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
    head=$(git rev-parse --verify HEAD 2>/dev/null); then
        ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

export PATH="$TC_DIR/bin:$PATH"

DEFCONFIG="sagami_defconfig"

msg() {
    echo -e "\e[1;32m$1\e[0m"
}

m() {
    make -j$(nproc) O=out ARCH=arm64 CC="ccache clang" LLVM=1 LLVM_IAS=1 \
        DTC_EXT="$(command -v dtc)" TARGET_PRODUCT=$TARGET "$@" || exit $?
}

$DO_CLEAN && {
    rm -rf out
    echo "Cleaned output directories."
}

$REGEN_DEFCONFIG && {
    msg "\nRegenerating config...\n"
    m $DEFCONFIG savedefconfig || return
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
    msg "\nSuccessfully regenerated defconfig at '$DEFCONFIG'\n"
    exit
}

msg "\nGenerating config...\n"
mkdir -p out
m $DEFCONFIG
m ./scripts/kconfig/merge_config.sh $DEFCONFIG vendor/${TARGET}_QGKI.config

msg "\nBuilding kernel for '$TARGET'...\n"
m 2> >(tee out/error.log >&2)

kernel="out/arch/arm64/boot/Image"
dtb_dir="out/arch/arm64/boot/dts/vendor/qcom"
dtbo_dir="out/arch/arm64/boot/dts/vendor/somc"

if [[ -f $kernel && -d $dtb_dir && -d $dtbo_dir ]]; then
    msg "\nKernel compiled succesfully! Zipping up...\n"
    if [[ -d $AK3_DIR ]]; then
        cp -r $AK3_DIR AnyKernel3
        git -C AnyKernel3 checkout sagami &>/dev/null
    else
        if ! git clone -q https://github.com/BladeRunner-A2C/AnyKernel3 -b sagami --depth=1; then
            echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
            exit 1
        fi
    fi
    cp $kernel AnyKernel3
    cat $dtb_dir/*.dtb > AnyKernel3/dtb
    python3 scripts/dtc/libfdt/mkdtboimg.py create AnyKernel3/dtbo.img --page_size=4096 $dtbo_dir/*.dtbo
    rm -rf out/arch/arm64/boot
    cd AnyKernel3
    zip -r9 ../$ZIPNAME * -x .git README.md *placeholder
    cd ..
    rm -rf AnyKernel3
    msg "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !\n"
    echo "Zip: $(realpath $ZIPNAME)"
    echo -e "\nUploading..."
    output=$(curl --progress-bar -T "$ZIPNAME" -u :"$PD_API_KEY" https://pixeldrain.com/api/file/)
    id=$(echo $output | jq -r '.id')
    echo -e "\nDownload URL: https://pixeldrain.com/api/file/$id?download\n"
else
    echo -e "\nCompilation failed!"
    exit 1
fi
