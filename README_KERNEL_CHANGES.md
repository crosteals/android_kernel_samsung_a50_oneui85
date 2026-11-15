# Kernel for One UI 8.5 port — Galaxy A50 (SM-A505F)

This branch is the exact kernel source used in the **One UI 8.5 A50 port v3** (made by korutsune, tested by Spricola145).

It is based on **Mint Kernel** by TenSeventy7 / FreshROMs:
`https://github.com/TenSeventy7/android_kernel_samsung_exynos9610_mint`, commit
`7f72a8b689677562f028d78b2e91bd79277a0aba` (Mint 4.14.194, Beta 1413). All credit for Mint goes to its authors.

## Changes on top of Mint

| Commit | File(s) | Why |
|---|---|---|
| `bpf: lpm_trie: implement get_next_key and delete_elem` | `kernel/bpf/lpm_trie.c` | Mint 4.14 still has the stubs `trie_get_next_key = -ENOTSUPP` and `trie_delete_elem = -ENOSYS`. Android 16 `netd` iterates and deletes LPM-trie BPF maps during boot (`local_net_access`), so `system_server` crashed and the port did not boot. Both functions are backported from Linux stable, keeping Mint's raw spinlock. |
| `fs: sdfat: add time_offset mount option` | `fs/sdfat/sdfat.c`, `sdfat.h`, `misc.c` | The Android 16 `vold` passes `time_offset=<minutes>` when mounting FAT/exFAT microSD cards. Samsung sdFAT rejected the unknown option, so the card failed to mount. The option is parsed (range ±1440 min) and used for FAT local-time conversion; `tz=UTC` keeps its old meaning. |
| `cpufreq: schedutil: fix next frequency formula` | `kernel/sched/cpufreq_schedutil.c` | `get_next_freq()` had `freq = freq + (freq >> 2) * util / max;` — the result is always ≥ `policy->max`, so both clusters stayed at maximum frequency regardless of load (big battery drain). Restored the upstream formula `freq = (freq + (freq >> 2)) * util / max;`. |

No other source file differs from Mint `7f72a8b`.

## KernelSU

Submodule `KernelSU` → `https://github.com/rsuntk/KernelSU.git`, commit
`32548de0179fb1b075c87f5ff19751ea6db12f25`. The build sets `-DKSU_VERSION=12132` in
`KernelSU/kernel/Makefile` (the version is normally derived from git history, which a
source archive does not have).

## Build

- Toolchain: Mint toolchain (Proton clang 13.0.0), `https://gitlab.com/TenSeventy7/exynos9610_toolchains_fresh`
- Config = `arch/arm64/configs/exynos9610-a50_core_defconfig` + `kernel/configs/mint_partial-deknox-12.config`
  + `mint_mali-12.config` + `mint_variant_oneui.config` + `mint_root-kernelsu.config`
- `LOCALVERSION=" - Mint Beta 1413"`, `KBUILD_BUILD_USER=Clembot`, `KBUILD_BUILD_HOST=Lumiose-CI`
- See `build_a50_oneui85.sh` in this branch.

The released `boot.img` keeps the ramdisk of the original port image. After building, the
`init_uts_ns` release string `4.14.194 - Mint Beta 1413` in `Image` is overwritten with
`5.10.250` (same field length, no code change), because the One UI 8.5 userspace checks the
reported kernel release. `linux_banner` and module vermagic are not changed.
