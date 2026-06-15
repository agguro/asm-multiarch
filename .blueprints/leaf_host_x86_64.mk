# ==============================================================================
# LOW-LEVEL FRAMEWORK: CPU HOST ENGINE (PROJECT LOCAL)
# BPI-BLUEPRINT: .blueprints/leaf_host.mk
# ==============================================================================

CURRENT_DIR   := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NAME          := $(notdir $(CURRENT_DIR))
SRC_ROOT      := $(patsubst %/x86_64/$(NAME)/,%,$(CURRENT_DIR)/)

# LAUNCH_ROOT context blijft behouden voor orchestration
ifndef LAUNCH_ROOT
        export LAUNCH_ROOT := $(abspath $(CURRENT_DIR)/../../)/
endif

MODE          ?= debug

# ARCHITECTUUR DEFINITIE (In de toekomst makkelijk parametriseerbaar te maken voor aarch64)
ARCH          := x86_64

# ANKERING BINNEN HET PROJECT ZELF
BIN_DIR       := $(SRC_ROOT)/bin/$(MODE)/$(ARCH)/$(NAME)
BUILD_DIR     := $(SRC_ROOT)/build/$(MODE)/$(ARCH)/$(NAME)
KERNEL_BUILD  := $(SRC_ROOT)/build/$(MODE)/kernels/$(NAME)

# Paden naar overige resources
KERNEL_DIR   := $(SRC_ROOT)/kernels/$(NAME)
INC_DIR      := $(SRC_ROOT)/$(ARCH)/include
LIB_DIR      := $(SRC_ROOT)/$(ARCH)/lib

# TOOLCHAIN CONFIGURATIE
AS           := as
LD           := ld

ASFLAGS      := --64 -msyntax=att -mmnemonic=att -I$(BUILD_DIR) -I$(INC_DIR) -I$(LIB_DIR) -I$(KERNEL_DIR) -I$(KERNEL_BUILD)
LDFLAGS      := -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L/usr/local/cuda/lib64 -L/usr/lib/x86_64-linux-gnu -lcuda -lc -lcrypto -lssl

ifeq ($(MODE),debug)
        ASFLAGS    += -g
        LDFLAGS    += -g
        MSG        := "Build Mode: DEBUG"
else
        LDFLAGS    += -s
        MSG        := "Build Mode: RELEASE"
endif

SRC_HOST  := $(CURRENT_DIR)/$(NAME).s
OBJ       := $(BUILD_DIR)/$(NAME).o
LST       := $(BUILD_DIR)/$(NAME).lst
TARGET    := $(BIN_DIR)/$(NAME)

-include $(CURRENT_DIR)/MakefileLists.mk
LIB_SOURCES_BARE := $(notdir $(LIB_SOURCES))
LIB_SOURCES_FULL := $(addprefix $(LIB_DIR)/,$(LIB_SOURCES_BARE))
EXTRA_OBJS   := $(patsubst $(LIB_DIR)/%.s,$(BUILD_DIR)/obj_%.o,$(LIB_SOURCES_FULL))
ALL_OBJS     := $(OBJ) $(EXTRA_OBJS)

all: debug

debug release: directories info check_kernel $(TARGET)

info:
        @echo "=============================================================================="
        @echo $(MSG) "for Host Target [$(NAME)]"
        @echo "Project Root: $(SRC_ROOT)"
        @echo "Host Source:  $(SRC_HOST)"
        @if [ -n "$(LIB_SOURCES_BARE)" ]; then echo "Lib Sources:  $(LIB_SOURCES_BARE) (resolved via $(LIB_DIR)/)"; fi
        @echo "Target:       $(TARGET)"
        @echo "=============================================================================="

check_kernel:
        @if [ -d $(KERNEL_DIR) ] && [ -f $(KERNEL_DIR)/Makefile ]; then \
                $(MAKE) -C $(KERNEL_DIR) LAUNCH_ROOT=$(LAUNCH_ROOT) MODE=$(MODE); \
        fi

$(OBJ): $(SRC_HOST) | directories
        $(AS) $(ASFLAGS) -c $(SRC_HOST) -o $(OBJ) -a=$(LST)

$(BUILD_DIR)/obj_%.o: $(LIB_DIR)/%.s | directories
        $(AS) $(ASFLAGS) -c $< -o $@

$(TARGET): $(ALL_OBJS) | directories
        $(LD) $(LDFLAGS) $(ALL_OBJS) -o $(TARGET)
        @echo "--> Host Binary $(NAME) linked successfully!"

directories:
        @mkdir -p $(BIN_DIR)
        @mkdir -p $(BUILD_DIR)

clean:
        @echo "Cleaning up host build paths for $(NAME)..."
        rm -rf $(BUILD_DIR) $(BIN_DIR)
        @if [ -d $(KERNEL_DIR) ] && [ -f $(KERNEL_DIR)/Makefile ]; then \
                $(MAKE) -C $(KERNEL_DIR) LAUNCH_ROOT=$(LAUNCH_ROOT) clean; \
        fi

test:
        @$(TARGET)

install:
        @mkdir -p $(HOME)/asm-multiarch/bin/cuda/$(NAME)
        @cp $(TARGET) $(HOME)/asm-multiarch/bin/cuda/$(NAME)/$(NAME)

.PHONY: all debug release clean test install info check_kernel directories
