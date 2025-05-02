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
[![Platforms](https://img.shields.io/badge/platforms-aarch64|x86__64-brightgreen)](https://github.com/freedpom/FreedpomFlake)

NixOS and Home-Manager presets for reproducible system configurations.

## Project Description

FreedpomFlake provides reusable NixOS and Home-Manager modules for configuring systems in a declarative, reproducible manner. These presets leverage the power of Nix flakes to deliver version-controlled, easily composable system configurations.

## Features

## Installation

Add FreedpomFlake to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    freedpomFlake = {
      url = "github:freedpom/FreedpomFlake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

## Usage

### NixOS Configuration

```nix
{
  imports = [
    inputs.freedpomFlake.nixosModules.freedpomFlake
  ];

  # Your configuration here
}
```

### Home-Manager Configuration

```nix
{
  imports = [
    inputs.freedpomFlake.homeModules.freedpomFlake
  ];

  # Your configuration here
}
```

## Dependencies

FreedpomFlake relies on the following flake inputs:

- `nixpkgs`: The Nix packages collection
- `home-manager`: User environment configuration management
- `impermanence`: Tools for ephemeral root configurations
- `flake-parts`: Modular flake composition
- `flake-root`: Root directory detection for flakes
- `fpFmt`: FreedpomFormatter for consistent code formatting
