{
  inputs,
  lib,
  ...
}: {
  options.ff.system.home-manager.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable home-manager";
  };
  imports = lib.optionals (inputs ? home-manager) [./home-manager.nix];
}
