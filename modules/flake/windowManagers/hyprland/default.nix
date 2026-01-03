{ withSystem, wm-hypr, ... }:
{
  flake.nixosModules.windowManagers =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.ff.programs.hyprland;
    in
    {
      options.ff.programs.hyprland = {
        enable = lib.mkEnableOption "Enable Hyprland";
      };

      config = lib.mkIf cfg.enable {
        programs = {
          uwsm.enable = true;
          hyprland = {
            enable = true;
            withUWSM = true;
            package = wm-hypr.packages.${withSystem pkgs.stdenv.hostPlatform.system}.hyprland;
            portalPackage =
              wm-hypr.packages.${withSystem pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
          };
        };
        hardware.graphics =
          let
            hyprpkgs = wm-hypr.inputs.nixpkgs.legacyPackages.${withSystem pkgs.stdenv.hostPlatform.system};
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
      cfg = config.ff.desktop.hypr.land;
    in
    {
      options.ff.desktop.hypr.land = {
        enable = lib.mkEnableOption "Enable Hyprland configuration";
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
