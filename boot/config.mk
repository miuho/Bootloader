#
# Bootloader make configuration file.
#


#
# Specify here all targets that should be included in boot0.
#
BOOT_BOOT0_FILES = boot0.o

#
# Specify here all targets that should be included in boot1.
#
BOOT_BOOT1_FILES = boot1.o multiboot.o
