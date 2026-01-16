{ inputs, ... }:
{
  flake.nixosModules.windowManagers =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.windowManagers.niri;
    in
    {
      options.freedpom.windowManagers.niri = {
        enable = lib.mkEnableOption "Niri scrollable tiling Wayland compositor";
      };

      config = lib.mkIf cfg.enable {
        programs = {
          uwsm.enable = true;
          hyprland = {
            enable = true;
            withUWSM = true;
            package = inputs.wm-hypr.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
            portalPackage =
              inputs.wm-hypr.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
          };
        };
        hardware.graphics =
          let
            hyprpkgs = inputs.wm-hypr.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          {
            package = lib.mkForce hyprpkgs.mesa;
            enable32Bit = lib.mkForce true;
            package32 = lib.mkForce hyprpkgs.pkgsi686Linux.mesa;
          };
      };
    };
  flake.homeModules.windowManagers =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.freedpom.windowManagers.niri;
    in
    {
      options.freedpom.windowManagers.niri = {
        enable = lib.mkEnableOption "Niri user configuration";
      };
      config = lib.mkIf cfg.enable {
        home.pointerCursor.hyprcursor.enable = true;
        home.packages = with pkgs; [
          wl-clipboard
          hyprpolkitagent
          hyprland-qtutils
        ];

        wayland = {
          windowManager.hyprland = {
            enable = true;
            package = null;
            portalPackage = null;
            systemd = {
              enable = false;
              enableXdgAutostart = false;
            };
            xwayland.enable = true;
          };
        };
      };
    };
}
