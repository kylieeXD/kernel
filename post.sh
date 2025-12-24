#!/bin/bash
# Edit by Neko

HOME="${PWD}"
KERNEL_NAME="Kurumi Kernel"
NAME_KERNEL="Kurumi+"
BASE="Rebase"
ANDROID="11-16"
KERNEL_DIR="$PWD"
KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image"
KERNEL_DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"
KERNEL_DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"
KBUILD_COMPILER_STRING=$(${HOME}/../toolchain/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
AK3_DIR="$KERNEL_DIR/AK3"
PHONE="Poco X3 NFC"
DEVICE="vayu"
CHAT_ID="-1002377006405"
TOKEN="7634058501:AAH3Wdk16hD50nACQM8JfgJhVRdwQKMkK1o"

START_TIME=$(date +%s)

# Copy Image/dtbo/dtb to AnyKernel3
function copy() {
    for files in "$KERNEL_IMG" "$KERNEL_DTBO" "$KERNEL_DTB"; do
        if [ -f "$files" ]; then
            echo -e " Copy [$files] to AnyKernel3 directory"
            cp "$files" "$AK3_DIR"
        else
            echo -e ""
            echo -e " Image/dtb/dtbo is missing!"
            echo -e ""
            exit 1
        fi
    done
}

# Compress
function main() {
    echo -e " Done..."
    echo -e ""
    echo -e " Create ZIP..."
    cd "$AK3_DIR" || exit
    ZIP_NAME="${NAME_KERNEL}_${DEVICE}_$(date +'%d%m%Y_%H%M').zip"
    zip -r9 "$ZIP_NAME" ./*
    echo  -e " Sukses!!!  "
    echo  -e " "
}

sendInfo() {
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )"
    &>/dev/null
}

END_TIME=$(date +%s)  # Capture the end time AFTER push
DIFF=$((END_TIME - START_TIME))  # Calculate the time difference after push

sendInfo "<b>------ ${KERNEL_NAME} ------</b>" \
  "<b>Device:</b> <code>${PHONE}</code>" \
  "<b>Name:</b> <code>${NAME_KERNEL}</code>" \
  "<b>Base:</b> <code>${BASE}</code>" \
  "<b>Android:</b> <code>${ANDROID}</code>" \
  "<b>Commit:</b> <code>$(git log --pretty=format:'%h : %s' -2)</code>" \
  "<b>Compiler:</b> <code>${KBUILD_COMPILER_STRING}</code>"

push() {
    # Cek apakah file ZIP ada
    if [ ! -f "$AK3_DIR/$ZIP_NAME" ]; then
        echo "File $AK3_DIR/$ZIP_NAME tidak ditemukan!"
        exit 1
    fi

    # Kirim file ke Telegram menggunakan curl
    curl -F document=@"$AK3_DIR/$ZIP_NAME" "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="It's time to brick | <b>vayu</b>"
}

# Finish
function end() {
    echo  " "
    echo  " "
    echo  "#####################"
    echo  "  Lets Party Time    "
    echo  "#####################"
    echo  " "
}

# execute
copy
main
push "$AK3_DIR/$ZIP_NAME"
end
