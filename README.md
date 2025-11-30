```
 :::===== :::====  :::===== :::===== :::====  :::====  :::====  :::=======       :::===== :::      :::====  :::  === :::=====
 :::      :::  === :::      :::      :::  === :::  === :::  === ::: === ===      :::      :::      :::  === ::: ===  :::
 ======   =======  ======   ======   ===  === =======  ===  === === === ===      ======   ===      ======== ======   ======
 ===      === ===  ===      ===      ===  === ===      ===  === ===     ===      ===      ===      ===  === === ===  ===
 ===      ===  === ======== ======== =======  ===       ======  ===     ===      ===      ======== ===  === ===  === ========
```

# FreedpomFlake

![Flake Check](https://img.shields.io/github/actions/workflow/status/freedpom/FreedpomFlake/flake-check.yml?logo=nixos&logoColor=white&label=Flake%20Check&labelColor=%23779ECB)
![NixOS Version](https://img.shields.io/badge/NixOS-unstable-blue?logo=nixos&logoColor=white)
![License](https://img.shields.io/github/license/freedpom/FreedpomFlake?logo=opensourceinitiative&logoColor=white)
![Last Commit](https://img.shields.io/github/last-commit/freedpom/FreedpomFlake?logo=git&logoColor=white)
![Repo Size](https://img.shields.io/github/repo-size/freedpom/FreedpomFlake?logo=github&logoColor=white)

**The Freedom to Nix**

FreedpomFlake is designed with convenience in mind, providing sane but slightly opinionated defaults for performance and security while still being configurable to meet the users needs.

## Goals

Freedom isn't just about choice, it's also about freeing your time. FreedpomFlake embraces the Nix philosophy of declarative configuration while focusing on:

- **Convenience**: Aims to provide sane defaults that *just work™* for most users, no further config needed
- **Performance First**: Makes it easy to get the most out of your system with the least effort possible
- **Hardware Support**: Presets for all kinds of hardware with minimal modification needed
- **Minimal Overhead**: Eliminate unnecessary services and optimize resource usage

## Advanced Features

- **Preservation Module**: Provides some defaults for ephemeral root and home, attempts to read system and home-manager configurations to preserve all necessary directories
- **Performance Tweaks**: Enables various options for program priority and scheduling, optimizes pipewire, even provides the cachyOS kernel (eventually)
- **Multi-Architecture**: Support for both x86_64 and aarch64 (hopefully but not yet) platforms

## Installation

### 1. Add FreedpomFlake to your flake

flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    freedpomFlake = {
      url = "github:freedpom/FreedpomFlake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

  };
}
```

### 2. Import the modules

flake-parts(formatter):

```nix
{
  imports = [ inputs.freedpomFlake.fmtModule ];
}
```

nixos:

```nix
{
  imports = [ inputs.freedpomFlake.nixosModules.freedpomFlake ];
}
```

home-manager:

```nix
{
  imports = [ inputs.freedpomFlake.homeModules.freedpomFlake ];
}
```

### 3. BE FREE!!

## Security Notice

Some options may change security defaults in favor of performance, please review configurations carefully for your specific use case. 

## License

FreedpomFlake is licensed under the MIT License. See [LICENSE](LICENSE) for details.

______________________________________________________________________
