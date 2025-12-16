{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ff.wayland.windowManager.niri;
  toKDL = lib.hm.generators.toKDL { };

  mkOutputKDL =
    outputs:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: body:
        toKDL {
          output = [
            ({ inherit name; } // body)
          ];
        }
      ) outputs
    );

  configFile = pkgs.writeText "niri-config.kdl" (
    lib.concatStringsSep "\n" (
      [ ]
      ++ lib.optional (cfg.settings != { }) (toKDL (builtins.removeAttrs cfg.settings [ "output" ]))
      ++ lib.optional (cfg.settings ? output && cfg.settings.output != { }) (
        mkOutputKDL cfg.settings.output
      )
      ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig
    )
  );

  checkNiriConfig = pkgs.runCommandLocal "niri-config" { buildInputs = [ cfg.package ]; } ''
    niri validate --config ${configFile}
    cp ${configFile} $out
  '';

in
{
  options.ff.wayland.windowManager.niri = {

    enable = lib.mkEnableOption "Niri Wayland compositor configuration";

    package = lib.mkPackageOption pkgs "niri" {
      nullable = true;
    };

    portalPackage = lib.mkPackageOption pkgs "xdg-desktop-portal-gnome" {
      nullable = true;
    };

    xwayland.enable = lib.mkEnableOption "XWayland" // {
      default = true;
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };

      example = lib.literalExpression ''
        {
          input = { };
          binds = { };
          layout = { };

          output = {
            "eDP-1" = { };
          };
        }
      '';

      description = ''
        Structured Niri configuration.
        Keys map directly to top-level KDL nodes.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";

      example = ''
        window-rule { }
        include "other.kdl"
      '';

      description = "Raw KDL appended to the generated configuration.";
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      (lib.hm.assertions.assertPlatform "ff.wayland.windowManager.niri" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) (
      [ cfg.package ] ++ lib.optional cfg.xwayland.enable pkgs.xwayland-satellite
    );

    xdg.configFile."niri/config.kdl".source = checkNiriConfig;

    xdg.portal = {
      enable = lib.mkIf (cfg.portalPackage != null) (lib.mkOverride 500 true);

      extraPortals = lib.mkIf (cfg.portalPackage != null) [ cfg.portalPackage ];

      configPackages = lib.mkIf (cfg.package != null) (lib.mkDefault [ cfg.package ]);
    };
  };
}
