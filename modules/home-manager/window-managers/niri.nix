{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ff.wayland.windowManager.niri;
  kdl = import ./toKDL.nix { inherit lib; };
  toKDL = kdl.toKDL { };
  configFile = pkgs.writeText "niri-config.kdl" (
    lib.concatStringsSep "\n" (
      lib.optional (cfg.settings != { }) (toKDL cfg.settings)
      ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig
    )
  );
  checkNiriConfig =
    pkgs.runCommandLocal "niri-config"
      {
        buildInputs = [ cfg.package ];
        preferLocalBuild = true;
      }
      ''
        if ! niri validate --config ${configFile} 2>&1 | tee validation.log; then
          echo ""
          echo "==============================================="
          echo "Niri configuration validation failed!"
          echo "==============================================="
          echo ""
          echo "Generated KDL config:"
          echo "---"
          cat ${configFile}
          echo "---"
          echo ""
          echo "Validation output:"
          cat validation.log
          echo ""
          exit 1
        fi
        cp ${configFile} $out
      '';
in
{
  options.ff.wayland.windowManager.niri = {
    enable = lib.mkEnableOption "Niri configuration";
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
          input.mouse = {
            accel-profile = "flat";
            accel-speed = 0.0;
          };

          output = {
            "eDP-1" = {
              mode = "1920x1080@120";
              scale = 2.0;
            };
            "DP-2" = {
              mode = "2560x1440@144";
            };
          };

          binds = {
            "Super+Return".spawn = "alacritty";
            "Super+Q".close-window = true;
          };

          layout = {
            gaps = 8;
            focus-ring.width = 2;
          };
        }
      '';
      description = ''
        Structured Niri configuration that will be converted to KDL format.

        The `output` attribute set will automatically generate multiple
        top-level KDL nodes, one for each display.
      '';
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        window-rule { }
        include "other.kdl"
      '';
      description = "Raw KDL appended to the config.";
    };
  };
  config = lib.mkIf cfg.enable {
    # Automatically set _expand for output
    ff.wayland.windowManager.niri.settings =
      lib.mkIf (cfg.settings ? output && lib.isAttrs cfg.settings.output)
        {
          output._expand = lib.mkDefault true;
        };
    assertions = [
      (lib.hm.assertions.assertPlatform "ff.wayland.windowManager.niri" pkgs lib.platforms.linux)
      {
        assertion = !(cfg.settings ? output) || lib.isAttrs cfg.settings.output;
        message = ''
          ff.wayland.windowManager.niri.settings.output must be an attribute set.

          Expected format:
          output = {
            "eDP-1" = { mode = "1920x1080"; };
            "DP-2" = { mode = "2560x1440"; };
          };
        '';
      }
      {
        assertion = cfg.package != null;
        message = ''
          ff.wayland.windowManager.niri.package must be set.
          Either set it explicitly or ensure pkgs.niri is available.
        '';
      }
    ];
    home.packages = lib.mkIf (cfg.package != null) (
      [ cfg.package ] ++ lib.optional cfg.xwayland.enable pkgs.xwayland-satellite
    );
    xdg.configFile."niri/config.kdl" = {
      source = checkNiriConfig;
      onChange = ''
        # Reload niri if it's running
        if systemctl --user is-active niri-session.target >/dev/null 2>&1; then
          ${lib.getExe cfg.package} msg action reload-config || true
        fi
      '';
    };
    xdg.portal = {
      enable = lib.mkIf (cfg.portalPackage != null) (lib.mkOverride 500 true);
      extraPortals = lib.mkIf (cfg.portalPackage != null) [ cfg.portalPackage ];
      configPackages = lib.mkIf (cfg.package != null) (lib.mkDefault [ cfg.package ]);
    };
  };
}
