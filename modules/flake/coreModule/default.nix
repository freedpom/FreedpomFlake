{ self, ... }:
{
  imports = [
    ./services/ssh.nix
    ./programs/forgecode.nix
    ./programs/opencode.nix
  ];

  flake.nixosModules.core = {
    nixpkgs.overlays = [ self.overlays.default ];
  };
}
