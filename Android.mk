# Mesa 3-D graphics library
#
# Copyright (C) 2010-2011 Chia-I Wu <olvaffe@gmail.com>
# Copyright (C) 2010-2011 LunarG Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# BOARD_GPU_DRIVERS should be defined.  The valid values are
#
#   classic drivers:
#   gallium drivers: swrast r600g
#
# The main target is libGLES_mesa.  There is no classic drivers yet.

MESA_TOP := $(call my-dir)
MESA_COMMON_MK := $(MESA_TOP)/Android.common.mk
MESA_PYTHON2 := python

DRM_TOP := external/drm
DRM_GRALLOC_TOP := hardware/drm_gralloc

classic_drivers :=
gallium_drivers := swrast r600g

MESA_GPU_DRIVERS := $(BOARD_GPU_DRIVERS)

# warn about invalid drivers
invalid_drivers := $(filter-out \
	$(classic_drivers) $(gallium_drivers), $(MESA_GPU_DRIVERS))
ifneq ($(invalid_drivers),)
$(warning invalid GPU drivers: $(invalid_drivers))
# tidy up
MESA_GPU_DRIVERS := $(filter-out $(invalid_drivers), $(MESA_GPU_DRIVERS))
endif

# host and target must be the same arch to generate matypes.h
ifeq ($(TARGET_ARCH),$(HOST_ARCH))
MESA_ENABLE_ASM := true
else
MESA_ENABLE_ASM := false
endif

ifneq ($(filter $(classic_drivers), $(MESA_GPU_DRIVERS)),)
MESA_BUILD_CLASSIC := true
else
MESA_BUILD_CLASSIC := false
endif

ifneq ($(filter $(gallium_drivers), $(MESA_GPU_DRIVERS)),)
MESA_BUILD_GALLIUM := true
else
MESA_BUILD_GALLIUM := false
endif

ifneq ($(strip $(MESA_GPU_DRIVERS)),)

SUBDIRS := \
	src/mapi \
	src/glsl \
	src/mesa \
	src/egl/main

ifeq ($(strip $(MESA_BUILD_GALLIUM)),true)
SUBDIRS += src/gallium
endif

# ---------------------------------------
# Build libGLES_mesa
# ---------------------------------------

LOCAL_PATH := $(MESA_TOP)

include $(CLEAR_VARS)

LOCAL_SRC_FILES :=
LOCAL_CFLAGS :=
LOCAL_C_INCLUDES :=

LOCAL_STATIC_LIBRARIES :=
LOCAL_WHOLE_STATIC_LIBRARIES := libmesa_egl

LOCAL_SHARED_LIBRARIES := \
	libglapi \
	libdrm \
	libdl \
	libhardware \
	liblog \
	libcutils

ifeq ($(strip $(MESA_BUILD_GALLIUM)),true)

gallium_DRIVERS :=

# swrast
gallium_DRIVERS += libmesa_pipe_softpipe libmesa_winsys_sw_android

# r600g
ifneq ($(filter r600g, $(MESA_GPU_DRIVERS)),)
gallium_DRIVERS += libmesa_winsys_radeon
gallium_DRIVERS += libmesa_pipe_r600 libmesa_winsys_r600
endif

#
# Notes about the order here:
#
#  * libmesa_st_egl depends on libmesa_winsys_sw_android in $(gallium_DRIVERS)
#  * libmesa_st_mesa depends on libmesa_glsl
#  * libmesa_glsl depends on libmesa_glsl_utils
#
LOCAL_STATIC_LIBRARIES := \
	libmesa_egl_gallium \
	libmesa_st_egl \
	$(gallium_DRIVERS) \
	libmesa_st_mesa \
	libmesa_glsl \
	libmesa_glsl_utils \
	libmesa_gallium \
	$(LOCAL_STATIC_LIBRARIES)

endif # MESA_BUILD_GALLIUM

LOCAL_MODULE := libGLES_mesa
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/egl

include $(MESA_COMMON_MK)
include $(BUILD_SHARED_LIBRARY)

mkfiles := $(patsubst %,$(MESA_TOP)/%/Android.mk,$(SUBDIRS))
include $(mkfiles)

endif # MESA_GPU_DRIVERS