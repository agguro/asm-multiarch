# Linux Assembly Programming (Multi-Arch)

A modern approach to low-level Linux programming. This repository focuses on pure assembly and GPU acceleration using the native GNU toolchain.

---

## Supported Architectures
* **x86_64:** Current implementation.
* **ARM / RISC-V:** Planned support for a truly multi-architectural codebase.

## 🛠 Modern Toolchain
This project has been rebuilt to remove heavy framework dependencies and external runtimes. It relies exclusively on native, low-overhead tools:

* **Assembler:** `as` (The GNU Assembler)
* **Linker:** `ld` (The GNU Linker)
* **GPU Architecture:** `nvcc` (NVIDIA CUDA / PTX)
* **Build Automation:** **GNU Make** (leveraging direct toolchain control without hidden abstraction layers)

---

## Build Philosophy: Pure GNU Make
The build infrastructure relies entirely on standard Makefiles. By bypassing complex meta-build systems (like CMake or Meson), the project remains lightweight and free of external runtime dependencies (such as Python):

* **Deterministic Builds:** Direct control over compiler, assembler, and linker flags.
* **Zero Dependencies:** No requirement for high-level language interpreters or package managers in the build environment.
* **Strict Architecture Isolation:** Clean separation of cross-compilation flags for multi-arch targets.

---

## Project Structure

### Include Files
Direct conversions of C header files mapped for the GNU Assembler.
> **Note:** These includes are provided for low-level system mapping. While functional, they are updated and tested incrementally based on project requirements.

### Legacy Archive
Contains examples from the original **linuxnasm.be** collection, ported for the GNU toolchain and optimized for the new build flow.

---

## Build Instructions
To compile the architecture layers or run the verification targets, use the standard GNU Make toolchain:

```bash
# Compile the static/shared library targets
make

# Run the ABI compliance and integration tests
make test

# Clean the build artifacts
make clean
