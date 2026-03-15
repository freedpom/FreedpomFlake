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
      cfg = config.freedpom.windowManagers.hyprland;
    in
    {
      options.freedpom.windowManagers.hyprland = {
        enable = lib.mkEnableOption "Hyprland dynamic tiling Wayland compositor";
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
            package = hyprpkgs.mesa;
            enable32Bit = true;
            package32 = hyprpkgs.pkgsi686Linux.mesa;
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
      cfg = config.freedpom.windowManagers.hyprland;
    in
    {
      options.freedpom.windowManagers.hyprland = {
        enable = lib.mkEnableOption "Hyprland user configuration";
      };
      config = lib.mkIf cfg.enable {

        home.pointerCursor.hyprcursor.enable = true;
        home.packages = with pkgs; [
          hyprpolkitagent
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
  flake.modules.hjem.hyprland =
    { config, lib, ... }:
    let
      cfg = config.freedpom.windowManagers.hyprland;

      literalString = s: if lib.isBool s then lib.boolToString s else toString s;

      splitConf = {
        attrs = lib.filterAttrs (_: v: lib.isAttrs v) cfg.settings;
        lists = lib.filterAttrs (_: v: lib.isList v) cfg.settings;
      };

      # convert section config into single string
      sectionConf =
        s: lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "  ${n}=${literalString v}") s);

      # add section names to configs
      attrConf = lib.mapAttrsToList (n: v: "${n} {\n" + (sectionConf v) + "\n}\n") splitConf.attrs;

      listConf = lib.flatten (
        lib.mapAttrsToList (n: v: (lib.map (c: "${n}=${c}") v) ++ [ "" ]) splitConf.lists
      );

      finalConf = lib.concatStringsSep "\n" (attrConf ++ listConf);
    in
    {
      options.freedpom.windowManagers.hyprland = {
        enable = lib.mkEnableOption "Enable hyprland config generation";
        settings = lib.mkOption {
          type = lib.types.anything;
          default = { };
        };
      };
      config = lib.mkIf cfg.enable {
        xdg.config.files."hypr/hyprland.conf".text = finalConf;
      };
    };
}
