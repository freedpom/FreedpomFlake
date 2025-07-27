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

  # Stylix integration
  stylixEnabled = config.stylix.enable or false;
  stylixColors = config.stylix.base16Scheme or null;
  stylixFonts = config.stylix.fonts or null;

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

  # Convert hex color to RGB tuple
  hexToRgb =
    hex:
    let
      cleanHex = removePrefix "#" hex;
      r = toString (lib.trivial.fromHex (substring 0 2 cleanHex));
      g = toString (lib.trivial.fromHex (substring 2 2 cleanHex));
      b = toString (lib.trivial.fromHex (substring 4 2 cleanHex));
    in
    "${r}, ${g}, ${b}";

  # Build Stylix color arguments
  buildStylixColorArgs =
    if !cfg.stylix.enable || !stylixEnabled || stylixColors == null then
      [ ]
    else
      [
        "--palette=custom"
        "--palette-black=${hexToRgb stylixColors.base00}"
        "--palette-red=${hexToRgb stylixColors.base08}"
        "--palette-green=${hexToRgb stylixColors.base0B}"
        "--palette-yellow=${hexToRgb stylixColors.base0A}"
        "--palette-blue=${hexToRgb stylixColors.base0D}"
        "--palette-magenta=${hexToRgb stylixColors.base0E}"
        "--palette-cyan=${hexToRgb stylixColors.base0C}"
        "--palette-white=${hexToRgb stylixColors.base07}"
        "--palette-light-grey=${hexToRgb stylixColors.base05}"
        "--palette-dark-grey=${hexToRgb stylixColors.base03}"
        "--palette-light-red=${hexToRgb stylixColors.base08}"
        "--palette-light-green=${hexToRgb stylixColors.base0B}"
        "--palette-light-yellow=${hexToRgb stylixColors.base0A}"
        "--palette-light-blue=${hexToRgb stylixColors.base0D}"
        "--palette-light-magenta=${hexToRgb stylixColors.base0E}"
        "--palette-light-cyan=${hexToRgb stylixColors.base0C}"
        "--palette-foreground=${hexToRgb stylixColors.base05}"
        "--palette-background=${hexToRgb stylixColors.base00}"
      ];

  # Build kmscon command arguments
  buildKmsconArgs =
    kmsconConfig:
    let
      # Use Stylix font if enabled and no manual font specified
      fontName =
        if kmsconConfig.font.name != null then
          kmsconConfig.font.name
        else if cfg.stylix.enable && stylixEnabled && stylixFonts != null then
          stylixFonts.monospace.name
        else
          null;

      fontSize =
        if kmsconConfig.font.size != null then
          kmsconConfig.font.size
        else if cfg.stylix.enable && stylixEnabled && stylixFonts != null then
          (stylixFonts.sizes.terminal or stylixFonts.sizes.desktop or 12)
        else
          null;
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
    ++ (optional (
      kmsconConfig.palette != "default" && !cfg.stylix.enable
    ) "--palette=${kmsconConfig.palette}")
    ++ (optional (
      kmsconConfig.scrollbackSize != null
    ) "--sb-size=${toString kmsconConfig.scrollbackSize}")
    ++ buildStylixColorArgs
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
      type = types.oneOf [
        types.bool
        (types.listOf types.str)
      ];
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
      type = types.oneOf [
        types.bool
        (types.listOf types.str)
      ];
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
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional arguments to pass to kmscon";
            example = [
              "--xkb-layout=us"
              "--xkb-variant=colemak"
            ];
          };
        };
      };
      default = { };
      description = "Kmscon configuration options";
    };

    stylix = {
      enable = mkOption {
        type = types.bool;
        default = stylixEnabled;
        description = mdDoc ''
          Enable Stylix integration for kmscon.

          When enabled, kmscon will automatically use:
          - Stylix color scheme for terminal colors
          - Stylix monospace font (if no manual font specified)
          - Stylix font sizes

          Manual font and color settings take precedence over Stylix.
        '';
      };
    };
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
