{
  inputs,
  lib,
  ...
}: {
  imports =
    [
      ./font.nix
      ./networking.nix
      ./nix.nix
      ./performance.nix
      ./sysctl.nix
      ./systemd-boot.nix
      ./userConfig.nix
    ]
    ++ lib.optionals (lib.hasAttr "preservation" inputs) [./preservation.nix];
}
