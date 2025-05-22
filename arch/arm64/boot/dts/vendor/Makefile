vendor := $(srctree)/$(src)

ifneq "$(wildcard $(vendor)/somc)" ""
	subdir-y += somc
else ifneq "$(wildcard $(vendor)/qcom)" ""
	subdir-y += qcom
endif
