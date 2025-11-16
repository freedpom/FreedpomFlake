{
  config,
  inputs,
  lib,
  ...
}:
{
  # Allow disabling via the enable option, only enables if home-manager module is actually imported
  config =
    lib.mkIf config.ff.system.home-manager.enable
    && (config ? home-manager) {
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
