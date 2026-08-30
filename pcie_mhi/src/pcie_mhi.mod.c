#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};


MODULE_INFO(depends, "");

MODULE_ALIAS("pci:v000017CBd00000303sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd00000304sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd00000305sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd00000306sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd00000308sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd0000011Asv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd00000309sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v00001EACd00001001sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v00001EACd00001002sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v00001EACd00001004sv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v00001EACd0000100Bsv*sd*bc*sc*i*");
MODULE_ALIAS("pci:v000017CBd0000FFFFsv*sd*bc*sc*i*");
