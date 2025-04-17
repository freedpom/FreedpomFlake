{ lib, config, ... }:
let
  cfg = config.ff.disks;
in
{

  imports = [
    ./home.nix
    ./nix-store.nix
    ./temp.nix
  ];

  options.ff.disks = {
    enable = lib.mkEnableOption "Enable";
    nix-disk = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      example = "/dev/disk/by-id/nvme-";
      default = null;
    };
    home-disk = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      example = "/dev/disk/by-id/nvme-";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices.disk = {
      nix.device = cfg.nix-disk;
      home.device = cfg.home-disk;
    };
  };
}
