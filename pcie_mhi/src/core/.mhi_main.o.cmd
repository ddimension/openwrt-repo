savedcmd_core/mhi_main.o := aarch64-openwrt-linux-gcc -Wp,-MMD,core/.mhi_main.o.d -nostdinc -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi -I/vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/generated/uapi -include /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler-version.h -include /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kconfig.h -include /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler_types.h -D__KERNEL__ -mlittle-endian -DKASAN_SHADOW_SCALE_SHIFT= -Werror -std=gnu11 -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -mgeneral-regs-only -DCONFIG_CC_HAS_K_CONSTRAINT=1 -Wno-psabi -mabi=lp64 -fno-asynchronous-unwind-tables -fno-unwind-tables -mbranch-protection=pac-ret -Wa,-march=armv8.5-a -DARM64_ASM_ARCH='"armv8.5-a"' -DKASAN_SHADOW_SCALE_SHIFT= -fno-delete-null-pointer-checks -O2 -fno-allow-store-data-races -fstack-protector -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-stack-clash-protection -fmin-function-alignment=4 -fstrict-flex-arrays=3 -fno-strict-overflow -fno-stack-check -fconserve-stack -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Werror=strict-prototypes -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=2048 -Wno-main -Wno-dangling-pointer -Wvla-larger-than=1 -Wno-pointer-sign -Wcast-function-type -Wno-array-bounds -Wno-stringop-overflow -Wno-alloc-size-larger-than -Wimplicit-fallthrough=5 -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-packed-not-aligned -Wno-format-overflow -Wno-format-truncation -Wno-stringop-truncation -Wno-override-init -Wno-missing-field-initializers -Wno-type-limits -Wno-shift-negative-value -Wno-maybe-uninitialized -Wno-sign-compare -Wno-unused-parameter -g -fno-var-tracking -femit-struct-debug-baseonly -mstack-protector-guard=sysreg -mstack-protector-guard-reg=sp_el0 -mstack-protector-guard-offset=1160 -Wno-missing-prototypes -Wno-error  -DMODULE  -DKBUILD_BASENAME='"mhi_main"' -DKBUILD_MODNAME='"pcie_mhi"' -D__KBUILD_MODNAME=kmod_pcie_mhi -c -o core/mhi_main.o core/mhi_main.c  

source_core/mhi_main.o := core/mhi_main.c

deps_core/mhi_main.o := \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler-version.h \
    $(wildcard include/config/CC_VERSION_TEXT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kconfig.h \
    $(wildcard include/config/CPU_BIG_ENDIAN) \
    $(wildcard include/config/BOOGER) \
    $(wildcard include/config/FOO) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler_types.h \
    $(wildcard include/config/DEBUG_INFO_BTF) \
    $(wildcard include/config/PAHOLE_HAS_BTF_TAG) \
    $(wildcard include/config/FUNCTION_ALIGNMENT) \
    $(wildcard include/config/CC_HAS_SANE_FUNCTION_ALIGNMENT) \
    $(wildcard include/config/X86_64) \
    $(wildcard include/config/ARM64) \
    $(wildcard include/config/LD_DEAD_CODE_DATA_ELIMINATION) \
    $(wildcard include/config/LTO_CLANG) \
    $(wildcard include/config/HAVE_ARCH_COMPILER_H) \
    $(wildcard include/config/KCSAN) \
    $(wildcard include/config/CC_HAS_ASSUME) \
    $(wildcard include/config/CC_HAS_COUNTED_BY) \
    $(wildcard include/config/CC_HAS_MULTIDIMENSIONAL_NONSTRING) \
    $(wildcard include/config/UBSAN_INTEGER_WRAP) \
    $(wildcard include/config/CFI) \
    $(wildcard include/config/ARCH_USES_CFI_GENERIC_LLVM_PASS) \
    $(wildcard include/config/CC_HAS_ASM_INLINE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler_attributes.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler-gcc.h \
    $(wildcard include/config/ARCH_USE_BUILTIN_BSWAP) \
    $(wildcard include/config/SHADOW_CALL_STACK) \
    $(wildcard include/config/KCOV) \
    $(wildcard include/config/CC_HAS_TYPEOF_UNQUAL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/compiler.h \
    $(wildcard include/config/ARM64_PTR_AUTH_KERNEL) \
    $(wildcard include/config/ARM64_PTR_AUTH) \
    $(wildcard include/config/BUILTIN_RETURN_ADDRESS_STRIPS_PAC) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/debugfs.h \
    $(wildcard include/config/DEBUG_FS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/fs.h \
    $(wildcard include/config/FANOTIFY_ACCESS_PERMISSIONS) \
    $(wildcard include/config/READ_ONLY_THP_FOR_FS) \
    $(wildcard include/config/SMP) \
    $(wildcard include/config/FS_POSIX_ACL) \
    $(wildcard include/config/SECURITY) \
    $(wildcard include/config/CGROUP_WRITEBACK) \
    $(wildcard include/config/IMA) \
    $(wildcard include/config/FILE_LOCKING) \
    $(wildcard include/config/FSNOTIFY) \
    $(wildcard include/config/PREEMPTION) \
    $(wildcard include/config/EPOLL) \
    $(wildcard include/config/UNICODE) \
    $(wildcard include/config/FS_ENCRYPTION) \
    $(wildcard include/config/FS_VERITY) \
    $(wildcard include/config/LOCKDEP) \
    $(wildcard include/config/COMPAT) \
    $(wildcard include/config/MMU) \
    $(wildcard include/config/QUOTA) \
    $(wildcard include/config/FS_DAX) \
    $(wildcard include/config/SWAP) \
    $(wildcard include/config/BLOCK) \
    $(wildcard include/config/DEBUG_LOCK_ALLOC) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/vfsdebug.h \
    $(wildcard include/config/DEBUG_VFS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bug.h \
    $(wildcard include/config/GENERIC_BUG) \
    $(wildcard include/config/PRINTK) \
    $(wildcard include/config/BUG_ON_DATA_CORRUPTION) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/bug.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/stringify.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/asm-bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/brk-imm.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bug.h \
    $(wildcard include/config/BUG) \
    $(wildcard include/config/GENERIC_BUG_RELATIVE_POINTERS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compiler.h \
    $(wildcard include/config/TRACE_BRANCH_PROFILING) \
    $(wildcard include/config/PROFILE_ALL_BRANCHES) \
    $(wildcard include/config/OBJTOOL) \
    $(wildcard include/config/64BIT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/rwonce.h \
    $(wildcard include/config/LTO) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/rwonce.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kasan-checks.h \
    $(wildcard include/config/KASAN_GENERIC) \
    $(wildcard include/config/KASAN_SW_TAGS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/types.h \
    $(wildcard include/config/HAVE_UID16) \
    $(wildcard include/config/UID16) \
    $(wildcard include/config/ARCH_DMA_ADDR_T_64BIT) \
    $(wildcard include/config/PHYS_ADDR_T_64BIT) \
    $(wildcard include/config/ARCH_32BIT_USTAT_F_TINODE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/int-ll64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/int-ll64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/bitsperlong.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitsperlong.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/bitsperlong.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/posix_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/stddef.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/stddef.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/posix_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/posix_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kcsan-checks.h \
    $(wildcard include/config/KCSAN_WEAK_MEMORY) \
    $(wildcard include/config/KCSAN_IGNORE_ATOMICS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/instrumentation.h \
    $(wildcard include/config/NOINSTR_VALIDATION) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/once_lite.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/panic.h \
    $(wildcard include/config/PANIC_TIMEOUT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/stdarg.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/printk.h \
    $(wildcard include/config/MESSAGE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_QUIET) \
    $(wildcard include/config/EARLY_PRINTK) \
    $(wildcard include/config/PRINTK_INDEX) \
    $(wildcard include/config/DYNAMIC_DEBUG) \
    $(wildcard include/config/DYNAMIC_DEBUG_CORE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/init.h \
    $(wildcard include/config/MEMORY_HOTPLUG) \
    $(wildcard include/config/HAVE_ARCH_PREL32_RELOCATIONS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/build_bug.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kern_levels.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/linkage.h \
    $(wildcard include/config/ARCH_USE_SYM_ANNOTATIONS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/export.h \
    $(wildcard include/config/MODVERSIONS) \
    $(wildcard include/config/GENDWARFKSYMS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/linkage.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ratelimit_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bits.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/bits.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/const.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/const.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/bits.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/overflow.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/limits.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/limits.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/limits.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/const.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/param.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/param.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/param.h \
    $(wildcard include/config/HZ) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/param.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/spinlock_types_raw.h \
    $(wildcard include/config/DEBUG_SPINLOCK) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/spinlock_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/qspinlock_types.h \
    $(wildcard include/config/NR_CPUS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/qrwlock_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/byteorder.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/byteorder/little_endian.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/byteorder/little_endian.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/swab.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/swab.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/swab.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/swab.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/byteorder/generic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/lockdep_types.h \
    $(wildcard include/config/PROVE_RAW_LOCK_NESTING) \
    $(wildcard include/config/LOCK_STAT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/wait_bit.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/wait.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/list.h \
    $(wildcard include/config/LIST_HARDENED) \
    $(wildcard include/config/DEBUG_LIST) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/container_of.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/poison.h \
    $(wildcard include/config/ILLEGAL_POINTER_VALUE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/barrier.h \
    $(wildcard include/config/ARM64_PSEUDO_NMI) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/alternative-macros.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/cpucaps.h \
    $(wildcard include/config/ARM64_PAN) \
    $(wildcard include/config/ARM64_EPAN) \
    $(wildcard include/config/ARM64_SVE) \
    $(wildcard include/config/ARM64_SME) \
    $(wildcard include/config/ARM64_CNP) \
    $(wildcard include/config/ARM64_MTE) \
    $(wildcard include/config/ARM64_BTI) \
    $(wildcard include/config/ARM64_TLB_RANGE) \
    $(wildcard include/config/ARM64_POE) \
    $(wildcard include/config/ARM64_GCS) \
    $(wildcard include/config/ARM64_HAFT) \
    $(wildcard include/config/UNMAP_KERNEL_AT_EL0) \
    $(wildcard include/config/ARM64_ERRATUM_843419) \
    $(wildcard include/config/ARM64_ERRATUM_1742098) \
    $(wildcard include/config/ARM64_ERRATUM_2645198) \
    $(wildcard include/config/ARM64_ERRATUM_2658417) \
    $(wildcard include/config/CAVIUM_ERRATUM_23154) \
    $(wildcard include/config/NVIDIA_CARMEL_CNP_ERRATUM) \
    $(wildcard include/config/ARM64_WORKAROUND_REPEAT_TLBI) \
    $(wildcard include/config/ARM64_ERRATUM_3194386) \
    $(wildcard include/config/ARM64_ERRATUM_4193714) \
    $(wildcard include/config/HW_PERF_EVENTS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/cpucap-defs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/insn-def.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/barrier.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/spinlock.h \
    $(wildcard include/config/PREEMPT_RT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/typecheck.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/preempt.h \
    $(wildcard include/config/PREEMPT_COUNT) \
    $(wildcard include/config/DEBUG_PREEMPT) \
    $(wildcard include/config/TRACE_PREEMPT_TOGGLE) \
    $(wildcard include/config/PREEMPT_NOTIFIERS) \
    $(wildcard include/config/PREEMPT_DYNAMIC) \
    $(wildcard include/config/PREEMPT_NONE) \
    $(wildcard include/config/PREEMPT_VOLUNTARY) \
    $(wildcard include/config/PREEMPT) \
    $(wildcard include/config/PREEMPT_LAZY) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cleanup.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/err.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/errno.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/errno.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/errno-base.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/args.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/preempt.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/thread_info.h \
    $(wildcard include/config/THREAD_INFO_IN_TASK) \
    $(wildcard include/config/GENERIC_ENTRY) \
    $(wildcard include/config/ARCH_HAS_PREEMPT_LAZY) \
    $(wildcard include/config/HAVE_ARCH_WITHIN_STACK_FRAMES) \
    $(wildcard include/config/SH) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/restart_block.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/errno.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/errno.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/current.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bitops.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/kernel.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/sysinfo.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/generic-non-atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/bitops.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/builtin-__ffs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/builtin-ffs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/builtin-__fls.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/builtin-fls.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/ffz.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/fls64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/sched.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/hweight.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/arch_hweight.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/const_hweight.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/cmpxchg.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/lse.h \
    $(wildcard include/config/ARM64_LSE_ATOMICS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/atomic_ll_sc.h \
    $(wildcard include/config/CC_HAS_K_CONSTRAINT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/atomic/atomic-arch-fallback.h \
    $(wildcard include/config/GENERIC_ATOMIC64) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/atomic/atomic-long.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/atomic/atomic-instrumented.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/instrumented.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kmsan-checks.h \
    $(wildcard include/config/KMSAN) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/instrumented-atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/lock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/instrumented-lock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/non-atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/non-instrumented-non-atomic.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/le.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/bitops/ext2-atomic-setbit.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/thread_info.h \
    $(wildcard include/config/ARM64_SW_TTBR0_PAN) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/memory.h \
    $(wildcard include/config/ARM64_VA_BITS) \
    $(wildcard include/config/ARM64_16K_PAGES) \
    $(wildcard include/config/KASAN_SHADOW_OFFSET) \
    $(wildcard include/config/KASAN) \
    $(wildcard include/config/ARM64_4K_PAGES) \
    $(wildcard include/config/RANDOMIZE_BASE) \
    $(wildcard include/config/KASAN_HW_TAGS) \
    $(wildcard include/config/DEBUG_VIRTUAL) \
    $(wildcard include/config/EFI) \
    $(wildcard include/config/ARM_GIC_V3_ITS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sizes.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/page-def.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/page.h \
    $(wildcard include/config/PAGE_SHIFT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mmdebug.h \
    $(wildcard include/config/DEBUG_VM) \
    $(wildcard include/config/DEBUG_VM_IRQSOFF) \
    $(wildcard include/config/DEBUG_VM_PGFLAGS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/boot.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/sections.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/sections.h \
    $(wildcard include/config/HAVE_FUNCTION_DESCRIPTORS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/sysreg.h \
    $(wildcard include/config/BROKEN_GAS_INST) \
    $(wildcard include/config/ARM64_PA_BITS_52) \
    $(wildcard include/config/ARM64_64K_PAGES) \
    $(wildcard include/config/AMPERE_ERRATUM_AC04_CPU_23) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kasan-tags.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/gpr-num.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/sysreg-defs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bitfield.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/alternative.h \
    $(wildcard include/config/MODULES) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/memory_model.h \
    $(wildcard include/config/FLATMEM) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP) \
    $(wildcard include/config/SPARSEMEM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pfn.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/stack_pointer.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqflags.h \
    $(wildcard include/config/PROVE_LOCKING) \
    $(wildcard include/config/TRACE_IRQFLAGS) \
    $(wildcard include/config/IRQSOFF_TRACER) \
    $(wildcard include/config/PREEMPT_TRACER) \
    $(wildcard include/config/DEBUG_IRQFLAGS) \
    $(wildcard include/config/TRACE_IRQFLAGS_SUPPORT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqflags_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/irqflags.h \
    $(wildcard include/config/ARM64_DEBUG_PRIORITY_MASKING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/ptrace.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/cpufeature.h \
    $(wildcard include/config/ARM64_BTI_KERNEL) \
    $(wildcard include/config/ARM64_PA_BITS) \
    $(wildcard include/config/ARM64_HW_AFDBM) \
    $(wildcard include/config/ARM64_AMU_EXTN) \
    $(wildcard include/config/ARM64_LPA2) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/cputype.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/hwcap.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/hwcap.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/log2.h \
    $(wildcard include/config/ARCH_HAS_ILOG2_U32) \
    $(wildcard include/config/ARCH_HAS_ILOG2_U64) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/jump_label.h \
    $(wildcard include/config/JUMP_LABEL) \
    $(wildcard include/config/HAVE_ARCH_JUMP_LABEL_RELATIVE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/jump_label.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/insn.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kernel.h \
    $(wildcard include/config/PREEMPT_VOLUNTARY_BUILD) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_CALL) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_KEY) \
    $(wildcard include/config/PREEMPT_) \
    $(wildcard include/config/DEBUG_ATOMIC_SLEEP) \
    $(wildcard include/config/DYNAMIC_FTRACE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/align.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/align.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/array_size.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/hex.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kstrtox.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/math.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/div64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/div64.h \
    $(wildcard include/config/CC_OPTIMIZE_FOR_PERFORMANCE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/minmax.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sprintf.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/static_call_types.h \
    $(wildcard include/config/HAVE_STATIC_CALL) \
    $(wildcard include/config/HAVE_STATIC_CALL_INLINE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/trace_printk.h \
    $(wildcard include/config/TRACING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/instruction_pointer.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/util_macros.h \
    $(wildcard include/config/FOO_SUSPEND) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/wordpart.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cpumask.h \
    $(wildcard include/config/FORCE_NR_CPUS) \
    $(wildcard include/config/HOTPLUG_CPU) \
    $(wildcard include/config/DEBUG_PER_CPU_MAPS) \
    $(wildcard include/config/CPUMASK_OFFSTACK) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bitmap.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/find.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/string.h \
    $(wildcard include/config/BINARY_PRINTF) \
    $(wildcard include/config/FORTIFY_SOURCE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/string.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/string.h \
    $(wildcard include/config/ARCH_HAS_UACCESS_FLUSHCACHE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/fortify-string.h \
    $(wildcard include/config/CC_HAS_KASAN_MEMINTRINSIC_PREFIX) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bitmap-str.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cpumask_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/threads.h \
    $(wildcard include/config/BASE_SMALL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/gfp_types.h \
    $(wildcard include/config/SLAB_OBJ_EXT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/numa.h \
    $(wildcard include/config/NUMA_KEEP_MEMINFO) \
    $(wildcard include/config/NUMA) \
    $(wildcard include/config/HAVE_ARCH_NODE_DEV_GROUP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/nodemask.h \
    $(wildcard include/config/HIGHMEM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/nodemask_types.h \
    $(wildcard include/config/NODES_SHIFT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/random.h \
    $(wildcard include/config/VMGENID) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/random.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/ioctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/ioctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/ioctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/ioctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqnr.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/irqnr.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/ptrace.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/sve_context.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqchip/arm-gic-v3-prio.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/stacktrace/frame.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/percpu.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/percpu.h \
    $(wildcard include/config/HAVE_SETUP_PER_CPU_AREA) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/percpu-defs.h \
    $(wildcard include/config/ARCH_MODULE_NEEDS_WEAK_PER_CPU) \
    $(wildcard include/config/DEBUG_FORCE_WEAK_PER_CPU) \
    $(wildcard include/config/AMD_MEM_ENCRYPT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bottom_half.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/lockdep.h \
    $(wildcard include/config/DEBUG_LOCKING_API_SELFTESTS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/smp.h \
    $(wildcard include/config/UP_LATE_INIT) \
    $(wildcard include/config/CSD_LOCK_WAIT_DEBUG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/smp_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/llist.h \
    $(wildcard include/config/ARCH_HAVE_NMI_SAFE_CMPXCHG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/smp.h \
    $(wildcard include/config/ARM64_ACPI_PARKING_PROTOCOL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/mmiowb.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/mmiowb.h \
    $(wildcard include/config/MMIOWB) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/spinlock_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rwlock_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/spinlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/qspinlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/qspinlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/qrwlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/qrwlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/processor.h \
    $(wildcard include/config/KUSER_HELPERS) \
    $(wildcard include/config/ARM64_FORCE_52BIT) \
    $(wildcard include/config/HAVE_HW_BREAKPOINT) \
    $(wildcard include/config/ARM64_TAGGED_ADDR_ABI) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cache.h \
    $(wildcard include/config/ARCH_HAS_CACHE_LINE_SIZE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/cache.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/cache.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kasan-enabled.h \
    $(wildcard include/config/ARCH_DEFER_KASAN) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/static_key.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/mte-def.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/processor.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/vdso/processor.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/hw_breakpoint.h \
    $(wildcard include/config/CPU_PM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/virt.h \
    $(wildcard include/config/KVM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/kasan.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/mte-kasan.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/pgtable-types.h \
    $(wildcard include/config/PGTABLE_LEVELS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/pgtable-nopud.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/pgtable-nop4d.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/pgtable-hwdef.h \
    $(wildcard include/config/ARM64_CONT_PTE_SHIFT) \
    $(wildcard include/config/ARM64_CONT_PMD_SHIFT) \
    $(wildcard include/config/ARM64_VA_BITS_52) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/pointer_auth.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/prctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/spectre.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/fpsimd.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/sigcontext.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rwlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/spinlock_api_smp.h \
    $(wildcard include/config/INLINE_SPIN_LOCK) \
    $(wildcard include/config/INLINE_SPIN_LOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK_BH) \
    $(wildcard include/config/UNINLINE_SPIN_UNLOCK) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/GENERIC_LOCKBREAK) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rwlock_api_smp.h \
    $(wildcard include/config/INLINE_READ_LOCK) \
    $(wildcard include/config/INLINE_WRITE_LOCK) \
    $(wildcard include/config/INLINE_READ_LOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_LOCK_BH) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_READ_TRYLOCK) \
    $(wildcard include/config/INLINE_WRITE_TRYLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_BH) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQRESTORE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kdev_t.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/kdev_t.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dcache.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rculist.h \
    $(wildcard include/config/PROVE_RCU_LIST) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcupdate.h \
    $(wildcard include/config/PREEMPT_RCU) \
    $(wildcard include/config/TINY_RCU) \
    $(wildcard include/config/RCU_STRICT_GRACE_PERIOD) \
    $(wildcard include/config/RCU_LAZY) \
    $(wildcard include/config/RCU_STALL_COMMON) \
    $(wildcard include/config/NO_HZ_FULL) \
    $(wildcard include/config/VIRT_XFER_TO_GUEST_WORK) \
    $(wildcard include/config/RCU_NOCB_CPU) \
    $(wildcard include/config/TASKS_RCU_GENERIC) \
    $(wildcard include/config/TASKS_RCU) \
    $(wildcard include/config/TASKS_TRACE_RCU) \
    $(wildcard include/config/TASKS_RUDE_RCU) \
    $(wildcard include/config/TREE_RCU) \
    $(wildcard include/config/DEBUG_OBJECTS_RCU_HEAD) \
    $(wildcard include/config/PROVE_RCU) \
    $(wildcard include/config/ARCH_WEAK_RELEASE_ACQUIRE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched.h \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING_NATIVE) \
    $(wildcard include/config/SCHED_INFO) \
    $(wildcard include/config/SCHEDSTATS) \
    $(wildcard include/config/SCHED_CORE) \
    $(wildcard include/config/FAIR_GROUP_SCHED) \
    $(wildcard include/config/RT_GROUP_SCHED) \
    $(wildcard include/config/RT_MUTEXES) \
    $(wildcard include/config/UCLAMP_TASK) \
    $(wildcard include/config/UCLAMP_BUCKETS_COUNT) \
    $(wildcard include/config/KMAP_LOCAL) \
    $(wildcard include/config/MEM_ALLOC_PROFILING) \
    $(wildcard include/config/SCHED_CLASS_EXT) \
    $(wildcard include/config/CGROUP_SCHED) \
    $(wildcard include/config/CFS_BANDWIDTH) \
    $(wildcard include/config/BLK_DEV_IO_TRACE) \
    $(wildcard include/config/MEMCG_V1) \
    $(wildcard include/config/LRU_GEN) \
    $(wildcard include/config/COMPAT_BRK) \
    $(wildcard include/config/CGROUPS) \
    $(wildcard include/config/BLK_CGROUP) \
    $(wildcard include/config/PSI) \
    $(wildcard include/config/PAGE_OWNER) \
    $(wildcard include/config/EVENTFD) \
    $(wildcard include/config/ARCH_HAS_CPU_PASID) \
    $(wildcard include/config/X86_BUS_LOCK_DETECT) \
    $(wildcard include/config/TASK_DELAY_ACCT) \
    $(wildcard include/config/STACKPROTECTOR) \
    $(wildcard include/config/ARCH_HAS_SCALED_CPUTIME) \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING_GEN) \
    $(wildcard include/config/POSIX_CPUTIMERS) \
    $(wildcard include/config/POSIX_CPU_TIMERS_TASK_WORK) \
    $(wildcard include/config/KEYS) \
    $(wildcard include/config/SYSVIPC) \
    $(wildcard include/config/DETECT_HUNG_TASK) \
    $(wildcard include/config/IO_URING) \
    $(wildcard include/config/AUDIT) \
    $(wildcard include/config/AUDITSYSCALL) \
    $(wildcard include/config/DETECT_HUNG_TASK_BLOCKER) \
    $(wildcard include/config/UBSAN) \
    $(wildcard include/config/UBSAN_TRAP) \
    $(wildcard include/config/COMPACTION) \
    $(wildcard include/config/TASK_XACCT) \
    $(wildcard include/config/CPUSETS) \
    $(wildcard include/config/X86_CPU_RESCTRL) \
    $(wildcard include/config/FUTEX) \
    $(wildcard include/config/PERF_EVENTS) \
    $(wildcard include/config/NUMA_BALANCING) \
    $(wildcard include/config/RSEQ) \
    $(wildcard include/config/DEBUG_RSEQ) \
    $(wildcard include/config/SCHED_MM_CID) \
    $(wildcard include/config/FAULT_INJECTION) \
    $(wildcard include/config/LATENCYTOP) \
    $(wildcard include/config/KUNIT) \
    $(wildcard include/config/FUNCTION_GRAPH_TRACER) \
    $(wildcard include/config/MEMCG) \
    $(wildcard include/config/UPROBES) \
    $(wildcard include/config/BCACHE) \
    $(wildcard include/config/VMAP_STACK) \
    $(wildcard include/config/LIVEPATCH) \
    $(wildcard include/config/BPF_SYSCALL) \
    $(wildcard include/config/KSTACK_ERASE) \
    $(wildcard include/config/KSTACK_ERASE_METRICS) \
    $(wildcard include/config/RANDOMIZE_KSTACK_OFFSET) \
    $(wildcard include/config/X86_MCE) \
    $(wildcard include/config/KRETPROBES) \
    $(wildcard include/config/RETHOOK) \
    $(wildcard include/config/ARCH_HAS_PARANOID_L1D_FLUSH) \
    $(wildcard include/config/RV) \
    $(wildcard include/config/RV_PER_TASK_MONITORS) \
    $(wildcard include/config/USER_EVENTS) \
    $(wildcard include/config/UNWIND_USER) \
    $(wildcard include/config/SCHED_PROXY_EXEC) \
    $(wildcard include/config/MEM_ALLOC_PROFILING_DEBUG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/sched.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pid_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sem_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/shm.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/page.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/personality.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/personality.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/getorder.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/shmparam.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/shmparam.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kmsan_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mutex_types.h \
    $(wildcard include/config/MUTEX_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_MUTEXES) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/osq_lock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/plist_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/hrtimer_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timerqueue_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rbtree_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timer_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/seccomp_types.h \
    $(wildcard include/config/SECCOMP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/refcount_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/resource.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/resource.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/time_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/resource.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/resource.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/resource.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/latencytop.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/prio.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/signal_types.h \
    $(wildcard include/config/OLD_SIGACTION) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/signal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/signal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/signal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/signal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/signal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/signal-defs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/siginfo.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/siginfo.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/syscall_user_dispatch_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mm_types_task.h \
    $(wildcard include/config/ARCH_WANT_BATCHED_UNMAP_TLB_FLUSH) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/tlbbatch.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/netdevice_xmit.h \
    $(wildcard include/config/NET_EGRESS) \
    $(wildcard include/config/NET_ACT_MIRRED) \
    $(wildcard include/config/NF_DUP_NETDEV) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/task_io_accounting.h \
    $(wildcard include/config/TASK_IO_ACCOUNTING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/posix-timers_types.h \
    $(wildcard include/config/POSIX_TIMERS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/rseq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/seqlock_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kcsan.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rv.h \
    $(wildcard include/config/RV_LTL_MONITOR) \
    $(wildcard include/config/RV_REACTORS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/uidgid_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/tracepoint-defs.h \
    $(wildcard include/config/TRACEPOINTS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/unwind_deferred_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/kmap_size.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/kmap_size.h \
    $(wildcard include/config/DEBUG_KMAP_LOCAL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/generated/rq-offsets.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/ext.h \
    $(wildcard include/config/EXT_GROUP_SCHED) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/context_tracking_irq.h \
    $(wildcard include/config/CONTEXT_TRACKING_IDLE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcutree.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rculist_bl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/list_bl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bit_spinlock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/seqlock.h \
    $(wildcard include/config/CC_IS_GCC) \
    $(wildcard include/config/GCC_VERSION) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mutex.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/debug_locks.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/lockref.h \
    $(wildcard include/config/ARCH_USE_CMPXCHG_LOCKREF) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/generated/bounds.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/stringhash.h \
    $(wildcard include/config/DCACHE_WORD_ACCESS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/hash.h \
    $(wildcard include/config/HAVE_ARCH_HASH) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/path.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/stat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/stat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/stat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/stat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/stat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/time.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/math64.h \
    $(wildcard include/config/ARCH_SUPPORTS_INT128) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/math64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/time64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/time64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/time.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/time32.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timex.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/timex.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/timex.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER_OOL_WORKAROUND) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/percpu.h \
    $(wildcard include/config/RANDOM_KMALLOC_CACHES) \
    $(wildcard include/config/PAGE_SIZE_4KB) \
    $(wildcard include/config/NEED_PER_CPU_PAGE_FIRST_CHUNK) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/alloc_tag.h \
    $(wildcard include/config/MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/codetag.h \
    $(wildcard include/config/CODE_TAGGING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/clocksource/arm_arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timecounter.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/timex.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/time32.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/time.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/uidgid.h \
    $(wildcard include/config/MULTIUSER) \
    $(wildcard include/config/USER_NS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/highuid.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/list_lru.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/shrinker.h \
    $(wildcard include/config/SHRINKER_DEBUG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/refcount.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/completion.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/swait.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/xarray.h \
    $(wildcard include/config/XARRAY_MULTI) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/gfp.h \
    $(wildcard include/config/ZONE_DMA) \
    $(wildcard include/config/ZONE_DMA32) \
    $(wildcard include/config/ZONE_DEVICE) \
    $(wildcard include/config/CONTIG_ALLOC) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mmzone.h \
    $(wildcard include/config/ARCH_FORCE_MAX_ORDER) \
    $(wildcard include/config/PAGE_BLOCK_MAX_ORDER) \
    $(wildcard include/config/CMA) \
    $(wildcard include/config/MEMORY_ISOLATION) \
    $(wildcard include/config/ZSMALLOC) \
    $(wildcard include/config/UNACCEPTED_MEMORY) \
    $(wildcard include/config/IOMMU_SUPPORT) \
    $(wildcard include/config/HUGETLB_PAGE) \
    $(wildcard include/config/TRANSPARENT_HUGEPAGE) \
    $(wildcard include/config/LRU_GEN_STATS) \
    $(wildcard include/config/LRU_GEN_WALKS_MMU) \
    $(wildcard include/config/MEMORY_FAILURE) \
    $(wildcard include/config/PAGE_EXTENSION) \
    $(wildcard include/config/DEFERRED_STRUCT_PAGE_INIT) \
    $(wildcard include/config/HAVE_MEMORYLESS_NODES) \
    $(wildcard include/config/SPARSEMEM_EXTREME) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP_PREINIT) \
    $(wildcard include/config/HAVE_ARCH_PFN_VALID) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/list_nulls.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pageblock-flags.h \
    $(wildcard include/config/HUGETLB_PAGE_SIZE_VARIABLE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/page-flags-layout.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/sparsemem.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/pgtable-prot.h \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_WP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/rsi.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/rsi_cmds.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/arm-smccc.h \
    $(wildcard include/config/HAVE_ARM_SMCCC) \
    $(wildcard include/config/ARM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/uuid.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/rsi_smc.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mm_types.h \
    $(wildcard include/config/HAVE_ALIGNED_STRUCT_PAGE) \
    $(wildcard include/config/HUGETLB_PMD_PAGE_TABLE_SHARING) \
    $(wildcard include/config/SLAB_FREELIST_HARDENED) \
    $(wildcard include/config/USERFAULTFD) \
    $(wildcard include/config/ANON_VMA_NAME) \
    $(wildcard include/config/PER_VMA_LOCK) \
    $(wildcard include/config/HAVE_ARCH_COMPAT_MMAP_BASES) \
    $(wildcard include/config/MEMBARRIER) \
    $(wildcard include/config/FUTEX_PRIVATE_HASH) \
    $(wildcard include/config/ARCH_HAS_ELF_CORE_EFLAGS) \
    $(wildcard include/config/AIO) \
    $(wildcard include/config/MMU_NOTIFIER) \
    $(wildcard include/config/SPLIT_PMD_PTLOCKS) \
    $(wildcard include/config/IOMMU_MM_DATA) \
    $(wildcard include/config/KSM) \
    $(wildcard include/config/MM_ID) \
    $(wildcard include/config/CORE_DUMP_DEFAULT_ELF_HEADERS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/auxvec.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/auxvec.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/auxvec.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kref.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rbtree.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/maple_tree.h \
    $(wildcard include/config/MAPLE_RCU_DISABLED) \
    $(wildcard include/config/DEBUG_MAPLE_TREE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rwsem.h \
    $(wildcard include/config/RWSEM_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_RWSEMS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/uprobes.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timer.h \
    $(wildcard include/config/DEBUG_OBJECTS_TIMERS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ktime.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/jiffies.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/jiffies.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/generated/timeconst.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/vdso/ktime.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timekeeping.h \
    $(wildcard include/config/POSIX_AUX_CLOCKS) \
    $(wildcard include/config/GENERIC_CMOS_UPDATE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/clocksource_ids.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/debugobjects.h \
    $(wildcard include/config/DEBUG_OBJECTS) \
    $(wildcard include/config/DEBUG_OBJECTS_FREE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/workqueue.h \
    $(wildcard include/config/DEBUG_OBJECTS_WORK) \
    $(wildcard include/config/FREEZER) \
    $(wildcard include/config/SYSFS) \
    $(wildcard include/config/WQ_WATCHDOG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/workqueue_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/percpu_counter.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/mmu.h \
    $(wildcard include/config/ARM64_E0PD) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/page-flags.h \
    $(wildcard include/config/PAGE_IDLE_FLAG) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_2) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_3) \
    $(wildcard include/config/MIGRATION) \
    $(wildcard include/config/HUGETLB_PAGE_OPTIMIZE_VMEMMAP) \
    $(wildcard include/config/DEBUG_KMAP_LOCAL_FORCE_MAP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/local_lock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/local_lock_internal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/zswap.h \
    $(wildcard include/config/ZSWAP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/memory_hotplug.h \
    $(wildcard include/config/ARCH_HAS_ADD_PAGES) \
    $(wildcard include/config/MEMORY_HOTREMOVE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/notifier.h \
    $(wildcard include/config/TREE_SRCU) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/srcu.h \
    $(wildcard include/config/TINY_SRCU) \
    $(wildcard include/config/NEED_SRCU_NMI_SAFE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcu_segcblist.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/srcutree.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcu_node_tree.h \
    $(wildcard include/config/RCU_FANOUT) \
    $(wildcard include/config/RCU_FANOUT_LEAF) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/topology.h \
    $(wildcard include/config/USE_PERCPU_NUMA_NODE_ID) \
    $(wildcard include/config/SCHED_SMT) \
    $(wildcard include/config/GENERIC_ARCH_TOPOLOGY) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/arch_topology.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/topology.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/topology.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/mm.h \
    $(wildcard include/config/MMU_LAZY_TLB_REFCOUNT) \
    $(wildcard include/config/ARCH_HAS_MEMBARRIER_CALLBACKS) \
    $(wildcard include/config/ARCH_HAS_SYNC_CORE_BEFORE_USERMODE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sync_core.h \
    $(wildcard include/config/ARCH_HAS_PREPARE_SYNC_CORE_CMD) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/coredump.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/radix-tree.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pid.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/capability.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/capability.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/semaphore.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/fcntl.h \
    $(wildcard include/config/ARCH_32BIT_OFF_T) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/fcntl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/uapi/asm/fcntl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/fcntl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/openat2.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/migrate_mode.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/percpu-rwsem.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcuwait.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/signal.h \
    $(wildcard include/config/SCHED_AUTOGROUP) \
    $(wildcard include/config/BSD_PROCESS_ACCT) \
    $(wildcard include/config/TASKSTATS) \
    $(wildcard include/config/STACK_GROWSUP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/signal.h \
    $(wildcard include/config/DYNAMIC_SIGFRAME) \
    $(wildcard include/config/PROC_FS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/jobctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/task.h \
    $(wildcard include/config/HAVE_EXIT_THREAD) \
    $(wildcard include/config/ARCH_WANTS_DYNAMIC_TASK_STRUCT) \
    $(wildcard include/config/HAVE_ARCH_THREAD_STRUCT_WHITELIST) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/uaccess.h \
    $(wildcard include/config/ARCH_HAS_SUBPAGE_FAULTS) \
    $(wildcard include/config/HARDENED_USERCOPY) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/fault-inject-usercopy.h \
    $(wildcard include/config/FAULT_INJECTION_USERCOPY) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/nospec.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ucopysize.h \
    $(wildcard include/config/HARDENED_USERCOPY_DEFAULT_ON) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/uaccess.h \
    $(wildcard include/config/CC_HAS_ASM_GOTO_OUTPUT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/kernel-pgtable.h \
    $(wildcard include/config/RELOCATABLE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/asm-extable.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/mte.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/extable.h \
    $(wildcard include/config/BPF_JIT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/access_ok.h \
    $(wildcard include/config/ALTERNATE_USER_ADDRESS_SPACE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cred.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/key.h \
    $(wildcard include/config/KEY_NOTIFICATIONS) \
    $(wildcard include/config/NET) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sysctl.h \
    $(wildcard include/config/SYSCTL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/sysctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/assoc_array.h \
    $(wildcard include/config/ASSOCIATIVE_ARRAY) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/user.h \
    $(wildcard include/config/VFIO_PCI_ZDEV_KVM) \
    $(wildcard include/config/IOMMUFD) \
    $(wildcard include/config/WATCH_QUEUE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ratelimit.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/posix-timers.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/alarmtimer.h \
    $(wildcard include/config/RTC_CLASS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/hrtimer.h \
    $(wildcard include/config/HIGH_RES_TIMERS) \
    $(wildcard include/config/TIME_LOW_RES) \
    $(wildcard include/config/TIMERFD) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/hrtimer_defs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/timerqueue.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcuref.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rcu_sync.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/delayed_call.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/errseq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ioprio.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/rt.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/iocontext.h \
    $(wildcard include/config/BLK_ICQ) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/ioprio.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/fs_types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mount.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mnt_idmapping.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/slab.h \
    $(wildcard include/config/FAILSLAB) \
    $(wildcard include/config/KFENCE) \
    $(wildcard include/config/SLUB_TINY) \
    $(wildcard include/config/SLUB_DEBUG) \
    $(wildcard include/config/SLAB_BUCKETS) \
    $(wildcard include/config/KVFREE_RCU_BATCHED) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/percpu-refcount.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kasan.h \
    $(wildcard include/config/KASAN_STACK) \
    $(wildcard include/config/KASAN_VMALLOC) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rw_hint.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/file_ref.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/unicode.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/fs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/quota.h \
    $(wildcard include/config/QUOTA_NETLINK_INTERFACE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/dqblk_xfs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dqblk_v1.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dqblk_v2.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dqblk_qtree.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/projid.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/quota.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/seq_file.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/string_helpers.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ctype.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/string_choices.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/device.h \
    $(wildcard include/config/GENERIC_MSI_IRQ) \
    $(wildcard include/config/ENERGY_MODEL) \
    $(wildcard include/config/PINCTRL) \
    $(wildcard include/config/ARCH_HAS_DMA_OPS) \
    $(wildcard include/config/DMA_DECLARE_COHERENT) \
    $(wildcard include/config/DMA_CMA) \
    $(wildcard include/config/SWIOTLB) \
    $(wildcard include/config/SWIOTLB_DYNAMIC) \
    $(wildcard include/config/ARCH_HAS_SYNC_DMA_FOR_DEVICE) \
    $(wildcard include/config/ARCH_HAS_SYNC_DMA_FOR_CPU) \
    $(wildcard include/config/ARCH_HAS_SYNC_DMA_FOR_CPU_ALL) \
    $(wildcard include/config/DMA_OPS_BYPASS) \
    $(wildcard include/config/DMA_NEED_SYNC) \
    $(wildcard include/config/IOMMU_DMA) \
    $(wildcard include/config/PM) \
    $(wildcard include/config/PM_SLEEP) \
    $(wildcard include/config/OF) \
    $(wildcard include/config/DEVTMPFS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dev_printk.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/energy_model.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kobject.h \
    $(wildcard include/config/UEVENT_HELPER) \
    $(wildcard include/config/DEBUG_KOBJECT_RELEASE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sysfs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kernfs.h \
    $(wildcard include/config/KERNFS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/idr.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kobject_ns.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/cpufreq.h \
    $(wildcard include/config/CPU_FREQ) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/topology.h \
    $(wildcard include/config/SCHED_CLUSTER) \
    $(wildcard include/config/SCHED_MC) \
    $(wildcard include/config/CPU_FREQ_GOV_SCHEDUTIL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/idle.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sched/sd_flags.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ioport.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/klist.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pm.h \
    $(wildcard include/config/VT_CONSOLE_SLEEP) \
    $(wildcard include/config/CXL_SUSPEND) \
    $(wildcard include/config/PM_CLK) \
    $(wildcard include/config/PM_GENERIC_DOMAINS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/device/bus.h \
    $(wildcard include/config/ACPI) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/device/class.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/device/devres.h \
    $(wildcard include/config/HAS_IOMEM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/device/driver.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/module.h \
    $(wildcard include/config/MODULE_STRIPPED) \
    $(wildcard include/config/MODULES_TREE_LOOKUP) \
    $(wildcard include/config/STACKTRACE_BUILD_ID) \
    $(wildcard include/config/ARCH_USES_CFI_TRAPS) \
    $(wildcard include/config/MODULE_SIG) \
    $(wildcard include/config/KALLSYMS) \
    $(wildcard include/config/BPF_EVENTS) \
    $(wildcard include/config/DEBUG_INFO_BTF_MODULES) \
    $(wildcard include/config/EVENT_TRACING) \
    $(wildcard include/config/KPROBES) \
    $(wildcard include/config/MODULE_UNLOAD) \
    $(wildcard include/config/CONSTRUCTORS) \
    $(wildcard include/config/FUNCTION_ERROR_INJECTION) \
    $(wildcard include/config/MITIGATION_RETPOLINE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/buildid.h \
    $(wildcard include/config/VMCORE_INFO) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kmod.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/umh.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/elf.h \
    $(wildcard include/config/ARCH_HAVE_EXTRA_ELF_NOTES) \
    $(wildcard include/config/ARCH_USE_GNU_PROPERTY) \
    $(wildcard include/config/ARCH_HAVE_ELF_PROT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/elf.h \
    $(wildcard include/config/COMPAT_VDSO) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/user.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/user.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/elf.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/elf-em.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/moduleparam.h \
    $(wildcard include/config/ALPHA) \
    $(wildcard include/config/PPC64) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rbtree_latch.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/error-injection.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/error-injection.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dynamic_debug.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/module.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/module.h \
    $(wildcard include/config/HAVE_MOD_ARCH_SPECIFIC) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/device.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pm_wakeup.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dma-direction.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/dma-mapping.h \
    $(wildcard include/config/DMA_API_DEBUG) \
    $(wildcard include/config/HAS_DMA) \
    $(wildcard include/config/NEED_DMA_MAP_STATE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/scatterlist.h \
    $(wildcard include/config/NEED_SG_DMA_LENGTH) \
    $(wildcard include/config/NEED_SG_DMA_FLAGS) \
    $(wildcard include/config/DEBUG_SG) \
    $(wildcard include/config/SGL_ALLOC) \
    $(wildcard include/config/ARCH_NO_SG_CHAIN) \
    $(wildcard include/config/SG_POOL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mm.h \
    $(wildcard include/config/HAVE_ARCH_MMAP_RND_BITS) \
    $(wildcard include/config/HAVE_ARCH_MMAP_RND_COMPAT_BITS) \
    $(wildcard include/config/MEM_SOFT_DIRTY) \
    $(wildcard include/config/ARCH_USES_HIGH_VMA_FLAGS) \
    $(wildcard include/config/ARCH_HAS_PKEYS) \
    $(wildcard include/config/ARCH_PKEY_BITS) \
    $(wildcard include/config/X86_USER_SHADOW_STACK) \
    $(wildcard include/config/PARISC) \
    $(wildcard include/config/SPARC64) \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_MINOR) \
    $(wildcard include/config/PPC32) \
    $(wildcard include/config/FIND_NORMAL_PAGE) \
    $(wildcard include/config/SHMEM) \
    $(wildcard include/config/HAVE_ARCH_TRANSPARENT_HUGEPAGE_PUD) \
    $(wildcard include/config/HAVE_GIGANTIC_FOLIOS) \
    $(wildcard include/config/ARCH_HAS_PTE_SPECIAL) \
    $(wildcard include/config/ARCH_SUPPORTS_PMD_PFNMAP) \
    $(wildcard include/config/ARCH_SUPPORTS_PUD_PFNMAP) \
    $(wildcard include/config/ASYNC_KERNEL_PGTABLE_FREE) \
    $(wildcard include/config/SPLIT_PTE_PTLOCKS) \
    $(wildcard include/config/HIGHPTE) \
    $(wildcard include/config/DEBUG_VM_RB) \
    $(wildcard include/config/PAGE_POISONING) \
    $(wildcard include/config/INIT_ON_ALLOC_DEFAULT_ON) \
    $(wildcard include/config/INIT_ON_FREE_DEFAULT_ON) \
    $(wildcard include/config/DEBUG_PAGEALLOC) \
    $(wildcard include/config/ARCH_WANT_OPTIMIZE_DAX_VMEMMAP) \
    $(wildcard include/config/HUGETLBFS) \
    $(wildcard include/config/MAPPING_DIRTY_HELPERS) \
    $(wildcard include/config/MSEAL_SYSTEM_MAPPINGS) \
    $(wildcard include/config/PAGE_POOL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pgalloc_tag.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mmap_lock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/range.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/page_ext.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/stacktrace.h \
    $(wildcard include/config/ARCH_STACKWALK) \
    $(wildcard include/config/STACKTRACE) \
    $(wildcard include/config/HAVE_RELIABLE_STACKTRACE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/page_ref.h \
    $(wildcard include/config/DEBUG_PAGE_REF) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pgtable.h \
    $(wildcard include/config/ARCH_HAS_NONLEAF_PMD_YOUNG) \
    $(wildcard include/config/ARCH_HAS_HW_PTE_YOUNG) \
    $(wildcard include/config/GUP_GET_PXX_LOW_HIGH) \
    $(wildcard include/config/ARCH_WANT_PMD_MKWRITE) \
    $(wildcard include/config/HAVE_ARCH_SOFT_DIRTY) \
    $(wildcard include/config/ARCH_ENABLE_THP_MIGRATION) \
    $(wildcard include/config/HAVE_ARCH_HUGE_VMAP) \
    $(wildcard include/config/X86_ESPFIX64) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/pgtable.h \
    $(wildcard include/config/PAGE_TABLE_CHECK) \
    $(wildcard include/config/ARM64_CONTPTE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/proc-fns.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/tlbflush.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mmu_notifier.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/interval_tree.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/fixmap.h \
    $(wildcard include/config/ACPI_APEI_GHES) \
    $(wildcard include/config/ARM_SDE_INTERFACE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/fixmap.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/por.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/page_table_check.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/pgtable_uffd.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/memremap.h \
    $(wildcard include/config/DEVICE_PRIVATE) \
    $(wildcard include/config/PCI_P2PDMA) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cacheinfo.h \
    $(wildcard include/config/ACPI_PPTT) \
    $(wildcard include/config/ARCH_HAS_CPU_CACHE_ALIASING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cpuhplock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/huge_mm.h \
    $(wildcard include/config/PGTABLE_HAS_HUGE_LEAVES) \
    $(wildcard include/config/PERSISTENT_HUGE_ZERO_FOLIO) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/vmstat.h \
    $(wildcard include/config/VM_EVENT_COUNTERS) \
    $(wildcard include/config/DEBUG_TLBFLUSH) \
    $(wildcard include/config/PER_VMA_LOCK_STATS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/vm_event_item.h \
    $(wildcard include/config/MEMORY_BALLOON) \
    $(wildcard include/config/BALLOON_COMPACTION) \
    $(wildcard include/config/X86) \
    $(wildcard include/config/DEBUG_STACK_USAGE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/io.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/early_ioremap.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/early_ioremap.h \
    $(wildcard include/config/GENERIC_EARLY_IOREMAP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/io.h \
    $(wildcard include/config/GENERIC_IOMAP) \
    $(wildcard include/config/TRACE_MMIO_ACCESS) \
    $(wildcard include/config/HAS_IOPORT) \
    $(wildcard include/config/GENERIC_IOREMAP) \
    $(wildcard include/config/HAS_IOPORT_MAP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/pci_iomap.h \
    $(wildcard include/config/PCI) \
    $(wildcard include/config/NO_GENERIC_PCI_IOPORT_MAP) \
    $(wildcard include/config/GENERIC_PCI_IOMAP) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/logic_pio.h \
    $(wildcard include/config/INDIRECT_PIO) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/fwnode.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/interrupt.h \
    $(wildcard include/config/IRQ_FORCED_THREADING) \
    $(wildcard include/config/GENERIC_IRQ_PROBE) \
    $(wildcard include/config/IRQ_TIMINGS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqreturn.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/hardirq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/context_tracking_state.h \
    $(wildcard include/config/CONTEXT_TRACKING_USER) \
    $(wildcard include/config/CONTEXT_TRACKING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ftrace_irq.h \
    $(wildcard include/config/HWLAT_TRACER) \
    $(wildcard include/config/OSNOISE_TRACER) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/vtime.h \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING) \
    $(wildcard include/config/IRQ_TIME_ACCOUNTING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/hardirq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/irq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/irq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/kvm_arm.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/esr.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/hardirq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irq.h \
    $(wildcard include/config/GENERIC_IRQ_EFFECTIVE_AFF_MASK) \
    $(wildcard include/config/GENERIC_IRQ_IPI) \
    $(wildcard include/config/IRQ_DOMAIN_HIERARCHY) \
    $(wildcard include/config/DEPRECATED_IRQ_CPU_ONOFFLINE) \
    $(wildcard include/config/GENERIC_IRQ_MIGRATION) \
    $(wildcard include/config/GENERIC_PENDING_IRQ) \
    $(wildcard include/config/HARDIRQS_SW_RESEND) \
    $(wildcard include/config/GENERIC_IRQ_CHIP) \
    $(wildcard include/config/GENERIC_IRQ_MULTI_HANDLER) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqhandler.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/io.h \
    $(wildcard include/config/STRICT_DEVMEM) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/irq_regs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/irq_regs.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irqdesc.h \
    $(wildcard include/config/GENERIC_IRQ_STAT_SNAPSHOT) \
    $(wildcard include/config/GENERIC_IRQ_DEBUGFS) \
    $(wildcard include/config/SPARSE_IRQ) \
    $(wildcard include/config/IRQ_DOMAIN) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/irq_work.h \
    $(wildcard include/config/IRQ_WORK) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/irq_work.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/hw_irq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/hw_irq.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/of.h \
    $(wildcard include/config/OF_DYNAMIC) \
    $(wildcard include/config/SPARC) \
    $(wildcard include/config/OF_PROMTREE) \
    $(wildcard include/config/OF_KOBJ) \
    $(wildcard include/config/OF_NUMA) \
    $(wildcard include/config/OF_OVERLAY) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/mod_devicetable.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/mei.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/mei_uuid.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/property.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/skbuff.h \
    $(wildcard include/config/NF_CONNTRACK) \
    $(wildcard include/config/BRIDGE_NETFILTER) \
    $(wildcard include/config/NET_TC_SKB_EXT) \
    $(wildcard include/config/MAX_SKB_FRAGS) \
    $(wildcard include/config/NET_SOCK_MSG) \
    $(wildcard include/config/SKB_EXTENSIONS) \
    $(wildcard include/config/NET_XGRESS) \
    $(wildcard include/config/WIRELESS) \
    $(wildcard include/config/IPV6_NDISC_NODETYPE) \
    $(wildcard include/config/IP_VS) \
    $(wildcard include/config/NETFILTER_XT_TARGET_TRACE) \
    $(wildcard include/config/NF_TABLES) \
    $(wildcard include/config/NET_SWITCHDEV) \
    $(wildcard include/config/NET_REDIRECT) \
    $(wildcard include/config/NETFILTER_SKIP_EGRESS) \
    $(wildcard include/config/SKB_DECRYPTED) \
    $(wildcard include/config/IP_SCTP) \
    $(wildcard include/config/NET_SCHED) \
    $(wildcard include/config/NET_RX_BUSY_POLL) \
    $(wildcard include/config/XPS) \
    $(wildcard include/config/NETWORK_SECMARK) \
    $(wildcard include/config/DEBUG_NET) \
    $(wildcard include/config/FAIL_SKB_REALLOC) \
    $(wildcard include/config/HAVE_EFFICIENT_UNALIGNED_ACCESS) \
    $(wildcard include/config/NETWORK_PHY_TIMESTAMPING) \
    $(wildcard include/config/XFRM) \
    $(wildcard include/config/MPTCP) \
    $(wildcard include/config/MCTP_FLOWS) \
    $(wildcard include/config/INET_PSP) \
    $(wildcard include/config/NET_DSA_TAG_OOB) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/bvec.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/highmem.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/cacheflush.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/cacheflush.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kgdb.h \
    $(wildcard include/config/HAVE_ARCH_KGDB) \
    $(wildcard include/config/KGDB) \
    $(wildcard include/config/KGDB_HONOUR_BLOCKLIST) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kprobes.h \
    $(wildcard include/config/KRETPROBE_ON_RETHOOK) \
    $(wildcard include/config/OPTPROBES) \
    $(wildcard include/config/KPROBES_ON_FTRACE) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ftrace.h \
    $(wildcard include/config/HAVE_FUNCTION_GRAPH_FREGS) \
    $(wildcard include/config/FUNCTION_TRACER) \
    $(wildcard include/config/HAVE_DYNAMIC_FTRACE_WITH_ARGS) \
    $(wildcard include/config/HAVE_FTRACE_REGS_HAVING_PT_REGS) \
    $(wildcard include/config/HAVE_REGS_AND_STACK_ACCESS_API) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_REGS) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_ARGS) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_DIRECT_CALLS) \
    $(wildcard include/config/STACK_TRACER) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_CALL_OPS) \
    $(wildcard include/config/FRAME_POINTER) \
    $(wildcard include/config/FUNCTION_GRAPH_RETVAL) \
    $(wildcard include/config/FTRACE_SYSCALLS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/trace_recursion.h \
    $(wildcard include/config/FTRACE_RECORD_RECURSION) \
    $(wildcard include/config/FTRACE_VALIDATE_RCU_IS_WATCHING) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/trace_clock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/trace_clock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/trace_clock.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kallsyms.h \
    $(wildcard include/config/KALLSYMS_ALL) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ptrace.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/pid_namespace.h \
    $(wildcard include/config/MEMFD_CREATE) \
    $(wildcard include/config/PID_NS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/nsproxy.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ns_common.h \
    $(wildcard include/config/IPC_NS) \
    $(wildcard include/config/NET_NS) \
    $(wildcard include/config/TIME_NS) \
    $(wildcard include/config/UTS_NS) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/ptrace.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/seccomp.h \
    $(wildcard include/config/HAVE_ARCH_SECCOMP_FILTER) \
    $(wildcard include/config/SECCOMP_FILTER) \
    $(wildcard include/config/CHECKPOINT_RESTORE) \
    $(wildcard include/config/SECCOMP_CACHE_DEBUG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/seccomp.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/seccomp.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/asm/unistd_compat_32.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/seccomp.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/unistd.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/unistd.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/unistd_64.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/ftrace.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/compat.h \
    $(wildcard include/config/ARCH_HAS_SYSCALL_WRAPPER) \
    $(wildcard include/config/X86_X32_ABI) \
    $(wildcard include/config/COMPAT_OLD_SIGACTION) \
    $(wildcard include/config/ODD_RT_SIGACTION) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/sem.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/sem.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/ipc.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rhashtable-types.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/ipc.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/ipcbuf.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/ipcbuf.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/sembuf.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/sembuf.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/socket.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/socket.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/socket.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/generated/uapi/asm/sockios.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/asm-generic/sockios.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/sockios.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/uio.h \
    $(wildcard include/config/ARCH_HAS_COPY_MC) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/uio.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/socket.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/if.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/libc-compat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/hdlc/ioctl.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/aio_abi.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/compat.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/compat.h \
    $(wildcard include/config/COMPAT_FOR_U64_ALIGNMENT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/syscall_wrapper.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/objpool.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/rethook.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/kprobes.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/kprobes.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/kgdb.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/debug-monitors.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/cacheflush.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/kmsan.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/highmem-internal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/checksum.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/arch/arm64/include/asm/checksum.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/in6.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/in6.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/asm-generic/checksum.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/netdev_features.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/flow_dissector.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/siphash.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/if_ether.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/pkt_cls.h \
    $(wildcard include/config/NET_CLS_ACT) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/pkt_sched.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/if_packet.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/page_frag_cache.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/flow.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/inet_dscp.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/netfilter/nf_conntrack_common.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/netfilter/nf_conntrack_common.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/net_debug.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/dropreason-core.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/net/netmem.h \
  core/mhi.h \
    $(wildcard include/config/MHI_DEBUG) \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/linux/miscdevice.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/uapi/linux/major.h \
  core/mhi_internal.h \
  /vol/release/chateau/openwrt/build_dir/target-aarch64_cortex-a53_musl/linux-qualcommax_ipq60xx/linux-6.18.41/include/generated/uapi/linux/version.h \

core/mhi_main.o: $(deps_core/mhi_main.o)

$(deps_core/mhi_main.o):
