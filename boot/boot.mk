# @file   Makefile
# @brief  Builds the bootloader.
# @author Mike Kasick <mkasick@andrew.cmu.edu>

BOOT0_START_ADDR = 0x7c00
BOOT1_START_ADDR = 0x1000

INFRASTRUCTURE_OVERRIDE_BOOTFDIMG = Yes

-include $(BOOTDIR)/config.mk

BOOT_SAMPLE_FILES = sample_boot1.o

BOOTCFLAGS  = -Wall -Werror -nostdinc -m32
BOOTLDFLAGS = -nostdlib -Wl,-N,--oformat,binary

$(BOOTDIR)/%: CFLAGS=$(BOOTCFLAGS)
$(BOOTDIR)/%: LDFLAGS=$(BOOTLDFLAGS)

BOOT_DEPS = $(BOOT_SAMPLE_FILES:%.o=$(BOOTDIR)/%.$(DEP_SUFFIX)) \
            $(BOOT_BOOT0_FILES:%.o=$(BOOTDIR)/%.$(DEP_SUFFIX)) \
            $(BOOT_BOOT1_FILES:%.o=$(BOOTDIR)/%.$(DEP_SUFFIX))

-include $(BOOT_DEPS)

BOOT_CLEANS = $(patsubst %,$(BOOTDIR)/%, $(BOOT_BOOT0_FILES) \
                                          $(BOOT_BOOT1_FILES) \
                                          $(BOOT_SAMPLE_FILES) ) \
              $(BOOT_DEPS)

## Tag bootfd.img as phony to force a rebuild after a make sample.
.PHONY: sample bootfd.img

sample: $(BUILDDIR)/boot0 $(BUILDDIR)/sample_boot1
	touch $(BUILDDIR)/empty_kernel
	./$(BOOTDIR)/mkimage.sh bootfd.img $^ $(BUILDDIR)/empty_kernel

bootfd.img: $(BUILDDIR)/boot0 $(BUILDDIR)/boot1 kernel.strip
	./$(BOOTDIR)/mkimage.sh bootfd.img $^

$(BUILDDIR)/boot0: $(BOOT_BOOT0_FILES:%=$(BOOTDIR)/%)
	mkdir -p $(BUILDDIR)
	$(CC) $(BOOTCFLAGS) $(BOOTLDFLAGS),-Ttext,$(BOOT0_START_ADDR) -o $@ $^

$(BUILDDIR)/boot1: $(BOOT_BOOT1_FILES:%=$(BOOTDIR)/%)
	mkdir -p $(BUILDDIR)
	$(CC) $(BOOTCFLAGS) $(BOOTLDFLAGS),-Ttext,$(BOOT1_START_ADDR) -o $@ $^

$(BUILDDIR)/sample_boot1: $(BOOT_SAMPLE_FILES:%=$(BOOTDIR)/%)
	mkdir -p $(BUILDDIR)
	$(CC) $(BOOTCFLAGS) $(BOOTLDFLAGS),-Ttext,$(BOOT1_START_ADDR) -o $@ $^
