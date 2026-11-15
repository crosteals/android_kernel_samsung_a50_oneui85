#!/bin/bash
# Build the One UI 8.5 A50 port kernel (Mint 4.14.194 + port fixes).
# Usage: ./build_a50_oneui85.sh /path/to/toolchain      (Mint toolchain, Proton clang 13)
set -euo pipefail
TC=${1:?toolchain path}
git submodule update --init KernelSU
sed -i 's/^ccflags-y += -DKSU_VERSION=16$/ccflags-y += -DKSU_VERSION=12132/' KernelSU/kernel/Makefile
export PATH="$TC/bin:$PATH" LD_LIBRARY_PATH="$TC/lib:${LD_LIBRARY_PATH:-}"
export ARCH=arm64 SUBARCH=arm64 ANDROID_MAJOR_VERSION=r PLATFORM_VERSION=11.0.0
export CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KCONFIG_BUILTINCONFIG="$PWD/arch/arm64/configs/exynos9610-a50_default_defconfig"
export KBUILD_BUILD_USER=Clembot KBUILD_BUILD_HOST=Lumiose-CI KBUILD_BUILD_VERSION=1
cfg=arch/arm64/configs/a50_oneui85_defconfig
cat arch/arm64/configs/exynos9610-a50_core_defconfig > "$cfg"
for part in partial-deknox-12 mali-12 variant_oneui root-kernelsu; do
    cat "kernel/configs/mint_$part.config" >> "$cfg"
done
args=(CC=clang 'HOSTCC=gcc -fcommon' HOSTCXX=g++ AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy
      OBJDUMP=llvm-objdump STRIP=llvm-strip 'LOCALVERSION= - Mint Beta 1413')
make "${args[@]}" a50_oneui85_defconfig
make "${args[@]}" -j"$(nproc)" Image
echo "Image: arch/arm64/boot/Image"
