```
 :::===== :::====  :::===== :::===== :::====  :::====  :::====  :::=======       :::===== :::      :::====  :::  === :::=====
 :::      :::  === :::      :::      :::  === :::  === :::  === ::: === ===      :::      :::      :::  === ::: ===  :::
 ======   =======  ======   ======   ===  === =======  ===  === === === ===      ======   ===      ======== ======   ======
 ===      === ===  ===      ===      ===  === ===      ===  === ===     ===      ===      ===      ===  === === ===  ===
 ===      ===  === ======== ======== =======  ===       ======  ===     ===      ===      ======== ===  === ===  === ========
```

# FreedpomFlake

[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platforms](https://img.shields.io/badge/platforms-aarch64%7Cx86__64-brightgreen)](https://github.com/freedpom/FreedpomFlake)

**True Freedom to Excel Through Deep Software and Hardware Configuration**

FreedpomFlake is a high-performance NixOS and Home-Manager configuration system designed for users who demand maximum control over their system's performance and efficiency. This flake provides comprehensive hardware optimization, kernel tuning, and software configuration to unlock your system's full potential while maintaining the reproducible, declarative benefits of NixOS.

## 🚀 Philosophy

Freedom isn't just about choice—it's about having the power to push your hardware and software to their absolute limits. FreedpomFlake embraces the NixOS philosophy of declarative configuration while focusing on:

- **Performance First**: Every configuration decision prioritizes speed and efficiency
- **Hardware Mastery**: Deep integration with your specific hardware components
- **Minimal Overhead**: Eliminate unnecessary services and optimize resource usage
- **Reproducible Excellence**: Consistent high-performance across deployments
- **Modular Architecture**: Reusable components for flexible system composition

## 🛡️ Advanced Features
- **Impermanence Support**: Ephemeral root configurations for enhanced security and performance
- **Modular Composition**: Flake-parts integration for clean, composable configurations
- **Consistent Formatting**: FreedpomFormatter (fpFmt) for standardized code style
- **Multi-Architecture**: Support for both x86_64 and aarch64 (hopefully but not yet) platforms

## 📋 Requirements

- NixOS 23.11 or later (unstable branch recommended)
- Flakes enabled in your Nix configuration
- Root access for hardware-level optimizations
- Basic understanding of NixOS configuration syntax

## 🚀 Installation

### 1. Enable Flakes (if not already enabled)

```bash
# Add to /etc/nixos/configuration.nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### 2. Add FreedpomFlake to your flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    freedpomFlake = {
      url = "github:freedpom/FreedpomFlake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### 3. Apply Configuration

```bash
# Clone your flake repository
git clone https://github.com/yourusername/your-nixos-config.git
cd your-nixos-config

# Build and switch to the configuration
sudo nixos-rebuild switch --flake .#your-hostname

# Or use Nix Helper
nh os switch /etc/nixos
```

## 🏗️ Dependencies

FreedpomFlake relies on the following flake inputs for maximum functionality and performance:

- **`nixpkgs`**: The Nix packages collection (unstable branch for latest optimizations)
- **`home-manager`**: User environment configuration management with performance tweaks
- **`impermanence`**: Tools for ephemeral root configurations and enhanced security
- **`flake-parts`**: Modular flake composition for clean architecture
- **`flake-root`**: Root directory detection for flakes
- **`fpFmt`**: FreedpomFormatter for consistent code formatting across all configurations

### Development Setup

```bash
# Clone with development tools
git clone --recursive https://github.com/freedpom/FreedpomFlake.git
cd FreedpomFlake

# Format code using fpFmt
nix fmt

# Run tests and checks
nix flake check
```

## 🛡️ Security Notice

While FreedpomFlake prioritizes performance, security is not a core focus right now. Some performance tweaks may adjust security defaults—review configurations carefully for your specific use case.

## 📄 License

FreedpomFlake is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**FreedpomFlake**: Unleash your system's true potential through the power of NixOS and Home-Manager configuration.
