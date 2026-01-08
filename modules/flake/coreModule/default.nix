{ self, ... }:
{
  imports = [
    ./services/ssh.nix
    ./programs/forgecode
  ];

  flake.nixosModules.core = {
    nixpkgs.overlays = [ self.overlays.default ];
  };
}
