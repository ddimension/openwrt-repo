savedcmd_pcie_mhi.o := aarch64-openwrt-linux-ld -EL  -maarch64elf --fatal-warnings -z noexecstack --no-warn-rwx-segments   -r -o pcie_mhi.o @pcie_mhi.mod 
