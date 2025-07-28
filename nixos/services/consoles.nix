{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ff.services.consoles;
  inherit (lib) concatStringsSep optional;

  # TODO: Stylix integration
  # HINT: Use config.lib.stylix.colors for color scheme
  # HINT: Use config.stylix.fonts for font configuration
  # HINT: Handle base16Scheme properly (might be string path to YAML)

  # Extract TTY number from string (e.g., "tty1" -> "1")
  extractTtyNum =
    ttyStr:
    let
      match = builtins.match ".*tty([0-9]+).*" ttyStr;
    in
    if match != null then builtins.head match else null;

  # Extract username from autologin string (e.g., "user@tty1" -> "user")
  extractUser =
    str:
    let
      match = builtins.match "([^@]+)@.*" str;
    in
    if match != null then builtins.head match else null;

  # Parse TTY specification into structured data
  parseTtySpec = spec: {
    tty = extractTtyNum spec;
    user = extractUser spec;
    autologin = builtins.match ".*@.*" spec != null;
  };

  # Generate default TTY list when bool is true
  generateDefaultTtys = count: map (i: "tty${toString i}") (range 1 count);

  # Normalize TTY configuration to list format
  normalizeTtyConfig =
    config:
    if isBool config then
      if config then generateDefaultTtys 6 else [ ]
    else if isList config then
      config
    else
      throw "Invalid TTY configuration type";

  # Process TTY configurations
  gettyTtys = normalizeTtyConfig cfg.getty;
  kmsconTtys = normalizeTtyConfig cfg.kmscon;
  allTtys = gettyTtys ++ kmsconTtys;

  # Parse all TTY specifications

  # Create systemd service for getty
  createGettyService =
    spec:
    let
      parsed = parseTtySpec spec;
      ttyNum = parsed.tty;
      inherit (parsed) user;
    in
    nameValuePair "getty@tty${ttyNum}" {
      enable = true;
      serviceConfig = {
        ExecStart = mkForce (
          if parsed.autologin && user != null then
            "${getExe' pkgs.util-linux "agetty"} --login-program ${pkgs.shadow}/bin/login --autologin ${user} --noclear %I $TERM"
          else
            "${getExe' pkgs.util-linux "agetty"} --login-program ${pkgs.shadow}/bin/login --noclear %I $TERM"
        );
        Type = "idle";
        Restart = "always";
        RestartSec = "0";
      };
      wantedBy = [ "multi-user.target" ];
    };

  # TODO: Implement Stylix color integration
  # HINT: Convert hex colors to RGB tuples for kmscon palette
  # HINT: Use format "--palette-black=255, 255, 255" for RGB values
  # HINT: Map base16 colors: base00=black, base08=red, base0B=green, etc.

  # Build kmscon command arguments
  buildKmsconArgs =
    kmsconConfig:
    let
      # TODO: Add Stylix font fallback
      # HINT: Use stylixFonts.monospace.name for font name
      # HINT: Use stylixFonts.sizes.terminal for font size
      fontName = kmsconConfig.font.name;
      fontSize = kmsconConfig.font.size;
    in
    [
      "--vt"
      "%I"
      "--login"
    ]
    ++ (optional (fontName != null) "--font-name=${fontName}")
    ++ (optional (fontSize != null) "--font-size=${toString fontSize}")
    ++ (optional (kmsconConfig.font.dpi != null) "--font-dpi=${toString kmsconConfig.font.dpi}")
    ++ (optional (!kmsconConfig.hwaccel) "--no-hwaccel")
    ++ (optional (!kmsconConfig.drm) "--no-drm")
    ++ (optional (kmsconConfig.palette != "default") "--palette=${kmsconConfig.palette}")
    ++ (optional (
      kmsconConfig.scrollbackSize != null
    ) "--sb-size=${toString kmsconConfig.scrollbackSize}")
    # Video/Display options
    ++ (optional (kmsconConfig.video.gpus != "all") "--gpus=${kmsconConfig.video.gpus}")
    ++ (optional (
      kmsconConfig.video.renderEngine != null
    ) "--render-engine=${kmsconConfig.video.renderEngine}")
    ++ (optional kmsconConfig.video.renderTiming "--render-timing")
    ++ (optional (!kmsconConfig.video.useOriginalMode) "--no-use-original-mode")
    # TODO: Add Stylix color arguments here when implemented
    ++ kmsconConfig.extraArgs;

  # Create systemd service for kmscon
  createKmsconService =
    spec:
    let
      parsed = parseTtySpec spec;
      ttyNum = parsed.tty;
      inherit (parsed) user;
      kmsconArgs = buildKmsconArgs cfg.kmsconConfig;
      argsStr = concatStringsSep " " kmsconArgs;
    in
    nameValuePair "kmsconvt@tty${ttyNum}" {
      enable = true;
      serviceConfig = {
        ExecStart = mkForce (
          if parsed.autologin && user != null then
            "${getExe pkgs.kmscon} ${argsStr} -- ${pkgs.shadow}/bin/login -f ${user}"
          else
            "${getExe pkgs.kmscon} ${argsStr} -- ${pkgs.shadow}/bin/login"
        );
        Type = "simple";
        Restart = "always";
        RestartSec = "0";
      };
      wantedBy = [ "multi-user.target" ];
    };

  # Validation functions
  validateTtyFormat = spec: extractTtyNum spec != null || throw "Invalid TTY format: ${spec}";

  validateUserExists =
    spec:
    let
      user = extractUser spec;
    in
    if user != null then user != "" || throw "Empty username in: ${spec}" else true;

in
{
  options.ff.services.consoles = {
    enable = mkEnableOption "console services configuration";

    getty = mkOption {
      type = types.either types.bool (
        types.listOf (types.strMatching "^(tty[0-9]+|[a-zA-Z0-9]+@tty[0-9]+)$")
      );
      default = false;
      description = mdDoc ''
        Configure getty on TTYs.

        - `true`: Enable on tty1-tty6
        - `false`: Disable
        - List: Enable on specified TTYs (e.g., ["tty1" "user@tty2"])

        Use "user@ttyN" format for autologin.
      '';
      example = [
        "user@tty1"
        "tty2"
        "tty3"
      ];
    };

    kmscon = mkOption {
      type = types.either types.bool (
        types.listOf (types.strMatching "^(tty[0-9]+|[a-zA-Z0-9]+@tty[0-9]+)$")
      );
      default = false;
      description = mdDoc ''
        Configure kmscon on TTYs.

        - `true`: Enable on tty1-tty6
        - `false`: Disable  
        - List: Enable on specified TTYs (e.g., ["tty1" "user@tty2"])

        Use "user@ttyN" format for autologin.
      '';
      example = [
        "user@tty1"
        "tty2"
      ];
    };

    kmsconConfig = mkOption {
      type = types.submodule {
        options = {
          font = {
            name = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Font name for kmscon";
              example = "monospace";
            };
            size = mkOption {
              type = types.nullOr types.ints.positive;
              default = null;
              description = "Font size in points";
              example = 12;
            };
            dpi = mkOption {
              type = types.nullOr types.ints.positive;
              default = null;
              description = "DPI value for fonts";
              example = 96;
            };
          };
          hwaccel = mkOption {
            type = types.bool;
            default = false;
            description = "Enable 3D hardware acceleration";
          };
          drm = mkOption {
            type = types.bool;
            default = true;
            description = "Use DRM if available";
          };
          palette = mkOption {
            type = types.str;
            default = "default";
            description = "Color palette to use";
            example = "solarized";
          };
          scrollbackSize = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = "Scrollback buffer size in lines";
            example = 1000;
          };
          video = {
            gpus = mkOption {
              type = types.enum [
                "all"
                "aux"
                "primary"
              ];
              default = "all";
              description = "GPU selection mode";
            };
            renderEngine = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Console renderer engine";
              example = "gltex";
            };
            renderTiming = mkOption {
              type = types.bool;
              default = false;
              description = "Print renderer timing information";
            };
            useOriginalMode = mkOption {
              type = types.bool;
              default = true;
              description = "Use original KMS video mode";
            };
          };
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = mdDoc ''
              Additional arguments to pass to kmscon.

              Useful for display-specific settings like:
              - `"--seats=seat0:card0-HDMI-A-1"` - Use specific output
              - Custom resolution or display configurations
            '';
            example = [
              "--xkb-layout=us"
              "--xkb-variant=colemak"
              "--seats=seat0:card0-HDMI-A-1"
            ];
          };
        };
      };
      default = { };
      description = "Kmscon configuration options";
    };

    # TODO: Re-implement Stylix integration
    # stylix = {
    #   enable = mkOption {
    #     type = types.bool;
    #     default = config.stylix.enable or false;
    #     description = "Enable Stylix integration for kmscon colors and fonts";
    #   };
    # };
  };

  config = mkIf cfg.enable {
    # Disable default console
    console.useXkbConfig = mkDefault true;

    # Create systemd services
    systemd.services =
      (listToAttrs (map createGettyService gettyTtys))
      // (listToAttrs (map createKmsconService kmsconTtys))
      # Disable getty on kmscon TTYs
      // (listToAttrs (
        map (
          spec:
          let
            ttyNum = extractTtyNum spec;
          in
          nameValuePair "getty@tty${ttyNum}" { enable = false; }
        ) kmsconTtys
      ));

    # System assertions for validation
    assertions = [
      {
        assertion =
          length gettyTtys == 0
          || length kmsconTtys == 0
          || length (intersectLists (map extractTtyNum gettyTtys) (map extractTtyNum kmsconTtys)) == 0;
        message = "Getty and kmscon cannot be configured on the same TTY";
      }
      {
        assertion = all validateTtyFormat allTtys;
        message = "All TTY specifications must contain 'ttyN' format";
      }
      {
        assertion = all validateUserExists allTtys;
        message = "Autologin specifications must have valid usernames";
      }
      {
        assertion = !(isList cfg.getty && length cfg.getty == 0);
        message = "Getty cannot be set to empty list";
      }
      {
        assertion = !(isList cfg.kmscon && length cfg.kmscon == 0);
        message = "Kmscon cannot be set to empty list";
      }
    ];
  };
}
