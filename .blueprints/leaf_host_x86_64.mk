# ==============================================================================
# LOW-LEVEL FRAMEWORK: CPU HOST ENGINE (AS & LD ONLY)
# BPI-BLUEPRINT: .blueprints/leaf_host_x86_64.mk
# ==============================================================================

CURRENT_DIR   := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NAME          := $(notdir $(CURRENT_DIR))
SRC_ROOT      := $(patsubst %/x86_64/$(NAME)/,%,$(CURRENT_DIR)/)

# LAUNCH_ROOT context-bepaling
ifndef LAUNCH_ROOT
        export LAUNCH_ROOT := $(abspath $(CURRENT_DIR)/../../)/
endif

# Categorie scan via fysieke pad-analyse
ifneq ($(findstring /projects/,$(CURRENT_DIR)),)
        CATEGORY := projects
else ifneq ($(findstring /cuda/,$(CURRENT_DIR)),)
        CATEGORY := cuda
else
        CATEGORY := .
endif

MODE          ?= debug
LAST_LAUNCH   := $(notdir $(patsubst %/,%,$(LAUNCH_ROOT)))
PROJECT_NAME  := $(notdir $(abspath $(SRC_ROOT)))

# ANKERING VAN DE BUILD- EN BIN-TREES
ifeq ($(CATEGORY),.)
        BIN_DIR      := $(LAUNCH_ROOT)bin/$(MODE)/x86_64/$(NAME)
        BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/x86_64/$(NAME)
else
        ifeq ($(LAST_LAUNCH),$(PROJECT_NAME))
                BIN_DIR      := $(LAUNCH_ROOT)bin/$(MODE)/x86_64/$(NAME)
                BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/x86_64/$(NAME)
        else
                BIN_DIR      := $(LAUNCH_ROOT)bin/$(MODE)/$(CATEGORY)/x86_64/$(NAME)
                BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/$(CATEGORY)/x86_64/$(NAME)
        endif
endif

# Paden naar headers, libraries en gerelateerde kernel build
KERNEL_DIR   := $(SRC_ROOT)/kernels/$(NAME)
KERNEL_BUILD := $(patsubst %/x86_64/$(NAME),%/kernels/$(NAME),$(BUILD_DIR))
INC_DIR      := $(SRC_ROOT)/x86_64/include
LIB_DIR      := $(SRC_ROOT)/x86_64/lib

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

# Inclusie van extra library sources via project-specifieke lijst
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
        @echo "Launch Root:  $(LAUNCH_ROOT)"
        @echo "Category:     $(CATEGORY)"
        @echo "Host Source:  $(SRC_HOST)"
        @if [ -n "$(LIB_SOURCES_BARE)" ]; then echo "Lib Sources:  $(LIB_SOURCES_BARE) (resolved via $(LIB_DIR)/)"; fi
        @echo "Target:       $(TARGET)"
        @echo "=============================================================================="

# Automatische cross-trigger: Als er een kernel map bestaat met een Makefile, bouw die eerst
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
        @mkdir -p $(HOME)/asm-multiarch/bin/cuda/$(CATEGORY)
        @cp $(TARGET) $(HOME)/asm-multiarch/bin/cuda/$(CATEGORY)/$(NAME)

.PHONY: all debug release clean test install info check_kernel directories
