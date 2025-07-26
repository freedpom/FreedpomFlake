{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ff.services.consoles;
in
{
  # Global options
  options.ff.services.consoles = {

    autologin = lib.mkEnableOption "Global autologin toggle";

    autologinUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Global autologin user (for this flake)";
    };

    # Console configuration
    getty = lib.mkOption {
      type = lib.types.oneOf [
        lib.types.bool
        lib.types.listOf
        (
          lib.types.str
          // {
            check = s: lib.strings.hasInfix "tty" s;
            description = "String containing tty#, can be prefaced with username@ for autologin";
          }
        )
      ];
      default = false;
      description = "Configure getty to run on specific ttys or all available ttys";
      example = ''
        [ "user@tty1" "tty3" "tty4" ] - autologin on user@tty#, run normally on other specified ttys
        true - run on all ttys not taken by other consoles, provides 2 consoles by default or fills to highest number used
        false - don't run at all
      '';
    };

    kmscon = lib.mkOption {
      type = lib.types.oneOf [
        lib.types.bool
        lib.types.listOf
        (
          lib.types.str
          // {
            check = s: lib.strings.hasInfix "tty" s;
            description = "String containing tty#, can be prefaced with username@ for autologin";
          }
        )
      ];
      default = false;
      description = "Configure kmscon to run on specific ttys or all available ttys";
      example = ''
        [ "user@tty1" "tty3" "tty4" ] - autologin on user@tty#, run normally on other specified ttys
        true - run on all ttys not taken by other consoles, provides 2 consoles by default
        false - don't run at all
      '';
    };

  };
  config = let
    mergedIds = if lib.isList cfg.getty && cfg.kmscon then cfg.getty ++ cfg.kmscon else if lib.isList cfg.getty then cfg.getty else if lib.isList cfg.kmscon then cfg.kmscon else throw "you broke it :("; # merge ttyids into a single list

    ttyIds = (ids: lib.flatten (lib.map (id: lib.strings.match ".*([t]+[t]+[y].*)" id) ids)); # filter tty identifiers from a list

    largeId = (ids: lib.foldl' (m: c: if c > m then c else m) (builtins.head (ttyIds v)) (builtins.tail (ttyIds ids))); # return highest tty identifier

    autologinAt = lib.filter (id: lib.strings.hasInfix "@" id) mergedIds; # filter for user@tty#

    userFilter = id: lib.strings.match "(.*)[@]" id;

    gettyUnit = id: {
      serviceConfig.ExecStart = [
        ""
        "${lib.getExe' pkgs.util-linux "agetty"} --login-program ${pkgs.shadow}/bin/login ${lib.optionals (lib.elem id autologinAt) "--autologin ${userFilter id}"}"
      ];
    };
  in 
  lib.mkIf cfg.getty != false || cfg.kmscon != false {
    console.enable = false; # Disable default console creation
    systemd.services = lib.genAttrs gettyAt gettyUnit // lib.genAttrs kmsAt kmsUnit;
    assertions = [
      {
        assertion = !(cfg.getty && cfg.kmscon);
        message = "Getty and kmscon cannot both be true";
      }
      {
        assertion = cfg.getty != [] && cfg.kmscon != [];
        message = "Neither getty nor kmscon can be set to an empty list";
      }
    ];
  };
}
