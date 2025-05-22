ifeq ($(and $(CONFIG_BUILD_ARM64_DT_OVERLAY),$(CONFIG_ARCH_SONY_SAGAMI)), y)

dtbo-$(CONFIG_MACH_SONY_PDX214) += lahaina-sagami-pdx214_generic-overlay.dtbo
dtbo-$(CONFIG_MACH_SONY_PDX215) += lahaina-sagami-pdx215_generic-overlay.dtbo
dtbo-$(CONFIG_MACH_SONY_PDX217) += lahaina-sagami-pdx217_generic-overlay.dtbo

LAHAINA_BOARDS += \
	../qcom/lahaina.dtb \
	../qcom/lahaina-v2.dtb \
	../qcom/lahaina-v2.1.dtb

ifeq ($(CONFIG_MACH_SONY_PDX214),y)
lahaina-sagami-pdx214_generic-overlay.dtbo-base := $(LAHAINA_BOARDS)
else ifeq ($(CONFIG_MACH_SONY_PDX215),y)
lahaina-sagami-pdx215_generic-overlay.dtbo-base := $(LAHAINA_BOARDS)
else ifeq ($(CONFIG_MACH_SONY_PDX217),y)
lahaina-sagami-pdx217_generic-overlay.dtbo-base := $(LAHAINA_BOARDS)
endif

else

dtb-$(CONFIG_MACH_SONY_PDX214) += \
	lahaina-v2-sagami-pdx214_generic.dtb
dtb-$(CONFIG_MACH_SONY_PDX215) += \
	lahaina-v2-sagami-pdx215_generic.dtb
dtb-$(CONFIG_MACH_SONY_PDX217) += \
	lahaina-v2-sagami-pdx217_generic.dtb

endif

always		:= $(dtb-y)
subdir-y	:= $(dts-dirs)
clean-files	:= *.dtb *.dtbo
