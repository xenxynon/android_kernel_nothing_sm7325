#!/usr/bin/env bash
make clean && make mrproper && rm -rf out
git clone --depth=1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git -b 17 clang
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
KERNEL_DIR="$(pwd)"
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export KBUILD_BUILD_HOST=ArchLinux
export KBUILD_BUILD_USER="Mayur"
IMAGE=out/arch/arm64/boot/Image
DTBO=out/arch/arm64/boot/dts/vendor/qcom/dtbo.img
DTB=out/arch/arm64/boot/dts/vendor/qcom/yupik.dtb
make O=out ARCH=arm64 phone1_defconfig
make -kj$(nproc --all) O=out ARCH=arm64 LLVM_IAS=1 LLVM=1  CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-androideabi- 2>&1 | tee build.l6og

token="7521439646:AAE07Jv7f3mPPIoz5aNXwBxlyaRqUySsYYw"
chat_id="-1002449506494"

rm -rf AnyKernel
git clone https://github.com/xenxynon/AnyKernel3

function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgEAAxkBAAEnKnJfZOFzBnwC3cPwiirjZdgTMBMLRAACugEAAkVfBy-aN927wS5blhsE" \
        -d chat_id=$chat_id
}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}

function zipping() {
	cp $IMAGE AnyKernel3
	cp $DTBO AnyKernel3
        cp $DTB AnyKernel3/dtb

	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
        cd ..
        push "build.log" "Build Completed Successfully"
        }

sticker
zipping
push
