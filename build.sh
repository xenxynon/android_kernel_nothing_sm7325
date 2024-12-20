#!/usr/bin/env bash


######-------------VARS------------#####
# Telegram
export token="7521439646:AAE07Jv7f3mPPIoz5aNXwBxlyaRqUySsYYw"
export chat_id="-1002490515422"


# Toolchain
git clone --depth=1 https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git -b 17 clang
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
export LINKER=ld.lld

# Host
export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
export KBUILD_BUILD_HOST="$(grep ^NAME= /etc/os-release | cut -d= -f2 | tr -d '"')"
export KBUILD_BUILD_USER="xenxynon"
export COMMIT_HEAD=$(git log --oneline -1)
export VERSION=v1
export DISTRO=$(source /etc/os-release && echo "${NAME}")

# files
export IMAGE=out/arch/arm64/boot/Image
export DTBO=out/arch/arm64/boot/dts/vendor/qcom/dtbo.img
export DTB=out/arch/arm64/boot/dts/vendor/qcom/yupik.dtb
export KERNEL_DIR="$(pwd)"
export CI_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Device name
export MODEL=Nothing
export DEVICE=Spacewar

# Date & timezone
export DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")
export TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
export ZIPNAME=Neutrino-BETA
export FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE}-${TANGGAL}.zip

# AnyKernel3
rm -rf AnyKernel && git clone https://github.com/xenxynon/AnyKernel3


function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgEAAxkBAAEnKnJfZOFzBnwC3cPwiirjZdgTMBMLRAACugEAAkVfBy-aN927wS5blhsE" \
        -d chat_id=$chat_id
}

function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
	}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}

function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
}

function compile() {
START=$(date +"%s")
	# Push Notification
	post_msg "<b>$KBUILD_BUILD_VERSION Kernel Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Linker : </b><code>$LINKER</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>HEAD : </b><a href='$CL'>$COMMIT_HEAD</a>"

	# Compile
        make clean && make mrproper && rm -rf out
        make O=out ARCH=arm64 phone1_defconfig
        make -kj$(nproc --all) O=out ARCH=arm64 LLVM_IAS=1 LLVM=1 LD=${LINKER} CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-androideabi- 2>&1 | tee build.log
}


function zip() {
           if ! [ -a "$IMAGE" ];
	   then
	       push "build.log" "Build Throws Errors"
	       #exit 1
	   else
	       post_msg " Kernel Compilation Finished. Started Zipping "

	cp $IMAGE AnyKernel3
	cp $DTBO AnyKernel3
        cp $DTB AnyKernel3/dtb

	# Zipping and Push Kernel
		cd AnyKernel3
        zip -r9 ${FINAL_ZIP} * -x  .git README.md
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
        cd ..
        push "build.log" "Build Completed Successfully"
        }

sticker
compile
zip
push
