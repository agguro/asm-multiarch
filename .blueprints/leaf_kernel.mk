# ==============================================================================
# LOW-LEVEL FRAMEWORK: PTX KERNEL ENGINE (GPU ONLY)
# BPI-BLUEPRINT: .blueprints/leaf_kernel.mk
# ==============================================================================

CURRENT_DIR   := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NAME          := $(notdir $(CURRENT_DIR))
SRC_ROOT      := $(patsubst %/kernels/$(NAME)/,%,$(CURRENT_DIR)/)

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

# ANKERING VAN DE BUILD-TREE
ifeq ($(CATEGORY),.)
        BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/kernels/$(NAME)
else
        ifeq ($(LAST_LAUNCH),$(PROJECT_NAME))
                BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/kernels/$(NAME)
        else
                BUILD_DIR    := $(LAUNCH_ROOT)build/$(MODE)/$(CATEGORY)/kernels/$(NAME)
        endif
endif

# TOOLCHAIN CONFIGURATIE
PTXAS         := ptxas
NVDISASM      := nvdisasm

# --- DYNAMISCHE GPU ARCHITECTUUR DETECTIE ---
DETECTED_CC := $(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader,nounits 2>/dev/null | head -n 1 | tr -d '.')

ifneq ($(DETECTED_CC),)
        GPU_ARCH := sm_$(DETECTED_CC)
else
        GPU_ARCH := sm_61
endif

PTXASFLAGS    := -v --gpu-name=$(GPU_ARCH)

ifeq ($(MODE),debug)
        PTXASFLAGS += --generate-line-info
        MSG        := "Build Mode: DEBUG (Target: $(GPU_ARCH))"
else
        PTXASFLAGS += -O3
        MSG        := "Build Mode: RELEASE (Target: $(GPU_ARCH))"
endif

PTX_SRC   := $(CURRENT_DIR)/$(NAME).ptx
PTX_OBJ   := $(BUILD_DIR)/$(NAME).cubin
SASS_DUMP := $(BUILD_DIR)/$(NAME).sass

all: debug

debug release: directories info $(PTX_OBJ) $(SASS_DUMP)

info:
        @echo "=============================================================================="
        @echo $(MSG) "for GPU Kernel [$(NAME)]"
        @echo "Launch Root:  $(LAUNCH_ROOT)"
        @echo "Kernel Src:   $(PTX_SRC)"
        @echo "Output Cubin: $(PTX_OBJ)"
        @echo "=============================================================================="

$(PTX_OBJ): $(PTX_SRC) | directories
        $(PTXAS) $(PTXASFLAGS) $(PTX_SRC) -o $(PTX_OBJ)
        @echo "--> GPU Kernel $(NAME).ptx assembled successfully into $(PTX_OBJ)!"

$(SASS_DUMP): $(PTX_OBJ)
        $(NVDISASM) -g $(PTX_OBJ) > $(SASS_DUMP)
        @echo "--> SASS file generated successfully: $(SASS_DUMP)"

directories:
        @mkdir -p $(BUILD_DIR)

clean:
        @echo "Cleaning up kernel build paths for $(NAME)..."
        rm -rf $(BUILD_DIR)

.PHONY: all debug release clean info directories
