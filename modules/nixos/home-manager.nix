{
  config,
  inputs,
  lib,
  ...
}:
{
  options.ff.system.home-manager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Default system configs for home-manager, can be disabled.";
  };

  config = lib.mkIf config.ff.system.home-manager.enable {
    home-manager = {
      backupFileExtension = "bk";
      extraSpecialArgs = {
        inherit inputs;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
