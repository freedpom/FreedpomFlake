{ self, ... }:
{
  imports = [
    # Hardware modules
    ./hardware/displays.nix
    ./hardware/audio.nix

    # System modules  
    ./system/nix.nix
    ./system/performance.nix
    ./system/boot.nix
    ./system/sysctl.nix
    ./system/fonts.nix
    ./system/users.nix

    # Service modules
    ./services/ssh.nix
    ./services/pipewire.nix
    ./services/networking.nix
    ./services/ntpd.nix
    ./services/ollama.nix
    ./services/vr.nix
    ./services/ananicy.nix
    ./services/consoles.nix
    ./services/containers/virtualisation.nix
    ./services/containers/caddy.nix

    # Program modules
    ./programs/forgecode.nix
    ./programs/opencode.nix
    ./programs/fuc.nix
    ./programs/sudo-rs.nix
    ./programs/uutils.nix
  ];

  flake.nixosModules.default = {
    nixpkgs.overlays = [ self.overlays.default ];
  };
}