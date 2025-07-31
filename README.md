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

**The Freedom to Nix**

FreedpomFlake is designed with convenience in mind, providing sane but slightly opinionated defaults for performance and security while still being configurable to meet the users needs.

## Philosophy

Freedom isn't just about choice, it's also about freeing your time. FreedpomFlake embraces the Nix philosophy of declarative configuration while focusing on:

- **Convenience**: Aims to provide sane defaults that *just work™* for most users, no further config needed
- **Performance First**: Makes it easy to get the most out of your system with the least effort possible
- **Hardware Support**: Presets for all kinds of hardware with minimal modification needed
- **Minimal Overhead**: Eliminate unnecessary services and optimize resource usage

## Advanced Features
- **Preservation Module**: Provides some defaults for ephemeral root and home, attempts to read system and home-manager configurations to preserve all necessary directories.
- **Performance Tweaks**: Enables various options for program priority and scheduling, optimizes pipewire, even provides the cachyOS kernel!(eventually)
- **Multi-Architecture**: Support for both x86_64 and aarch64 (hopefully but not yet) platforms

## Requirements

- NixOS 23.11 or later (unstable branch recommended)
- Flakes enabled in your Nix configuration

## Installation

### 1. Enable Flakes (if not already enabled)

```nix # configuration.nix
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
```

### 2. Add FreedpomFlake to your flake

```nix # flake.nix
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

```nix # configuration.nix
{
  imports = [ inputs.freedpomFlake.nixosModules.freedpomFlake ];
}
```

```nix # home.nix
{
  imports = [ inputs.freedpomFlake.homeModules.freedpomFlake ];
}
```

## Dependencies

FreedpomFlake relies on the following:

- **[nixpkgs](https://github.com/NixOS/nixpkgs)**: The Nix packages collection
- **[home-manager](https://github.com/nix-community/home-manager)**: User environment configuration management
- **[flake-parts](https://github.com/hercules-ci/flake-parts)**: Modular flake composition for clean architecture
- **[preservation](https://github.com/nix-community/preservation)**: Tools for ephemeral storage configurations
- **[flake-root](https://github.com/srid/flake-root)**: Root directory detection for flakes
- **[fpFmt](https://github.com/freedpom/FreedpomFormatter)**: Formatter presets for consistent code formatting


## Security Notice

Some options may change security defaults in favor of performance, please review configurations carefully for your specific use case.

## License

FreedpomFlake is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**FreedpomFlake**: Unleash your system's true potential through the power of NixOS and Home-Manager configuration.
