{
  config,
  inputs,
  lib,
  ...
}: {
  config = lib.mkIf config.ff.system.home-manager.enable {
    # Home Manager Settings
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
