{
  config,
  lib,
  ...
}:
let

  cfg = config.ff.useCmini;

  userOpts =
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.passwdEntry types.str;
          apply =
            x:
            assert (
              stringLength x < 32 || abort "Username '${x}' is longer than 31 characters which is not allowed!"
            );
            x;
          description = ''
            The name of the user account. If undefined, the name of the
            attribute set will be used.
          '';
        };
        homeModule = lib.mkOption {
          description = "Home-manager modules for the user";
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/home/module.nix";
        };
      };
    };
in

{
  options.ff.useCmini = {

    enableHM = lib.mkEnableOption "Enable home-manager";
    users = lib.mkOption {
      description = "List of users to add to the system";
      type = with types; attrsOf (submodule userOpts);
      default = { };
            example = {
        alice = {
          homeModule = /path/module.nix;
        };
      };
    };
  };

  # System level user settings
  config = {
    home-manager = lib.mkIf cfg.enableHM {
      users = lib.mkMerge (
        builtins.map (user: {
          ${user.name} = import cfg.users.${user.name}.homeModule;
        }) (builtins.attrNames cfg.users)
      );
    };
  };
}
