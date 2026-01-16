{ self, ... }:
{
  imports = [
    ./services/ssh.nix
    ./programs/forgecode.nix
    ./programs/opencode.nix
  ];

  flake.nixosModules.default = {
    nixpkgs.overlays = [ self.overlays.default ];
  };
}
