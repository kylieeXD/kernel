#!/bin/bash
# Edit by NekoTuru & AI
# Set up kernel directories and tools
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
TC_DIR="${kernel_dir}/../toolchain"
CLANG_DIR="${TC_DIR}/clang"
ARCH_DIR="${TC_DIR}/aarch64-linux-android-4.9"
ARM_DIR="${TC_DIR}/arm-linux-androideabi-4.9"
export CONFIG_FILE="surya_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST="Weeaboo"
export KBUILD_BUILD_USER="NekoTuru"
export PATH="$CLANG_DIR/bin:$ARCH_DIR/bin:$ARM_DIR/bin:$PATH"

# Setup toolchains & optional KernelSU
setup() {
    if ! [ -d "${CLANG_DIR}" ]; then
        echo "Clang not found! Downloading Google prebuilt..."
        mkdir -p "${CLANG_DIR}"
        wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0998f421320ae02fddabec8a78b91bf7620159f6/clang-r563880.tar.gz -O clang.tar.gz
        if [ $? -ne 0 ]; then
            echo "Download failed! Aborting..."
            exit 1
        fi
        echo "Extracting clang to ${CLANG_DIR}..."
        tar -xf clang.tar.gz -C "${CLANG_DIR}"
        rm -f clang.tar.gz
    fi

    if ! [ -d "${ARCH_DIR}" ]; then
        echo "gcc not found! Cloning to ${ARCH_DIR}..."
        if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${ARCH_DIR}; then
            echo "Cloning failed! Aborting..."
            exit 1
        fi
    fi

    if ! [ -d "${ARM_DIR}" ]; then
        echo "gcc_32 not found! Cloning to ${ARM_DIR}..."
        if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${ARM_DIR}; then
            echo "Cloning failed! Aborting..."
            exit 1
        fi
    fi
}

# Function to clean the build environment
clean_build() {
    echo ""
    echo "########### Starting build clean-up ###########"
    echo ""

    # Remove old build output if it exists
    if [ -d "${objdir}" ]; then
        echo "Removing old build output from ${objdir}..."
        rm -rf ${objdir}
        if [ $? -eq 0 ]; then
            echo "Successfully removed old build output."
        else
            echo "Error: Failed to remove build output from ${objdir}."
            exit 1
        fi
    else
        echo "No previous build output found, skipping removal."
    fi

    # Run make mrproper only if .config exists
    if [ -f "${kernel_dir}/.config" ]; then
        echo "Cleaning kernel configuration files using 'make mrproper'..."
        make mrproper -C ${kernel_dir}
        if [ $? -eq 0 ]; then
            echo "'make mrproper' completed successfully."
        else
            echo "Error: 'make mrproper' failed."
            exit 1
        fi
    else
        echo "No existing .config file found, skipping 'make mrproper'."
    fi

    echo ""
    echo "########### Build clean-up completed ###########"
    echo ""
}

# Function to generate defconfig
make_defconfig() {
    START=$(date +"%s")
    echo ""
    echo "########### Generating Defconfig ############"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
    echo "Defconfig generation completed."
    echo ""
}

# Function to compile kernel
compile() {
    cd ${kernel_dir}
    echo ""
    echo "######### Compiling kernel #########"
    echo ""
    make -j$(nproc --all) \
    O=${objdir} \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CLANG_TRIPLE=${ARCH_DIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE=${ARCH_DIR}/bin/aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=${ARM_DIR}/bin/arm-linux-gnueabi- \
    CROSS_COMPILE_COMPAT=${ARM_DIR}/bin/arm-linux-gnueabi- \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    STRIP=llvm-strip \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    READELF=llvm-readelf \
    HOSTCC=clang \
    HOSTCXX=clang++ \
    HOSTAR=llvm-ar \
    HOSTLD=ld.lld \
    LLVM=1 \
    LLVM_IAS=1 \
    CC="${CCACHE} clang" \
    $1
    echo ""
}

# Function to check compilation completion
completion() {
    COMPILED_IMAGE=${objdir}/arch/arm64/boot/Image
    COMPILED_DTBO=${objdir}/arch/arm64/boot/dtbo.img
    COMPILED_DTB=${objdir}/arch/arm64/boot/dtb.img

    # Check if compiled files exist
    if [[ -f ${COMPILED_IMAGE} && -f ${COMPILED_DTBO} && -f ${COMPILED_DTB} ]]; then
        echo ""
        echo "############################################"
        echo "####### Kernel Build Successful! ##########"
        echo "############################################"
        echo ""
    else
        echo ""
        echo "############################################"
        echo "##         Kernel Build Failed!           ##"
        echo "## Please check the build log for errors. ##"
        echo "############################################"
        echo ""
        exit 1
    fi
}

# Clean the build environment, generate defconfig, compile kernel, and check result
setup "$@"
clean_build
make_defconfig
compile
completion
