{
  lib,
  inputs,
  ...
}:
{
  options.ff.system.home-manager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Default system configs for home-manager, can be disabled.";
  };
  imports = lib.optionals (inputs ? home-manager) [ ./home-manager.nix ];
}
