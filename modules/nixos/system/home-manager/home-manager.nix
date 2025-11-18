{
  config,
  inputs,
  lib,
  ...
}:
{
  # Allow disabling via the enable option, only enables if home-manager module is actually imported
  # Me thinks this dosent work
  config = lib.mkIf (config ? home-manager) {
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
