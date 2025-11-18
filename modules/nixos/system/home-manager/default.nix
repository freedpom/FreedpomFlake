{
  lib,
  inputs,
  config,
  ...
}:
{
  options.ff.system.home-manager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Default system configs for home-manager, can be disabled.";
  };
  imports = lib.optionals (config.ff.system.home-manager.enable && inputs ? home-manager) [
    inputs.home-manager.nixosModules.home-manager
    ./home-manager.nix
  ];
}
