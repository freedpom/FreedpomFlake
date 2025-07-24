{
  config,
  lib,
  ...
}:
{
  # Configuration options for KMS console
  options.ff.services.consoles = {

    autologin = lib.mkEnableOption "Global autologin toggle";

    autologinUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Global autologin user";
    };

    # TTY configuration
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
        true - run on all ttys not taken by other consoles, provides 2 consoles by default or fills to highest number used
        false - don't run at all
        [ "user@tty1" "tty3" "tty4" ] - run on specified ttys
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
        true - run on all ttys not taken by other consoles, provides 2 consoles by default or fills to highest number used
        false - don't run at all
        [ "user@tty1" "tty3" "tty4" ] - run on specified ttys
      '';
    };

  };
  config = {

    systemd.services = { };
  };
}
