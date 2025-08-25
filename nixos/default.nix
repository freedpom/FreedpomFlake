{
  inputs,
  lib,
  ...
}: {
  imports =
    [
      # Directory imports
      ./security
      ./services
      ./system
      ./programs

      # Individual module imports
      ./common.nix
    ]
    ++ lib.optionals (lib.hasAttr "home-manager" inputs) [./home-manager.nix];
}
