{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.ff.services.consoles;

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

  # Create systemd service for kmscon
  createKmsconService =
    spec:
    let
      parsed = parseTtySpec spec;
      ttyNum = parsed.tty;
      inherit (parsed) user;
    in
    nameValuePair "kmsconvt@tty${ttyNum}" {
      enable = true;
      serviceConfig = {
        ExecStart = mkForce (
          if parsed.autologin && user != null then
            "${getExe pkgs.kmscon} --vt %I --login -- ${pkgs.shadow}/bin/login -f ${user}"
          else
            "${getExe pkgs.kmscon} --vt %I --login"
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
  };

  config = mkIf (cfg.enable) {
    # Disable default console
    console.useXkbConfig = mkDefault true;

    # Create systemd services
    systemd.services =
      (listToAttrs (map createGettyService gettyTtys))
      // (listToAttrs (map createKmsconService kmsconTtys))
      # Disable getty on kmscon TTYs
      // (listToAttrs (map (spec: 
        let ttyNum = extractTtyNum spec;
        in nameValuePair "getty@tty${ttyNum}" { enable = false; }
      ) kmsconTtys));

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
