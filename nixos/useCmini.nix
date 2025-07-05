{
  config,
  lib,
  ...
}:
let

  cfg = config.ff.useCmini;

in

{
  options.ff.useCmini = {

    enableHM = lib.mkEnableOption "Enable home-manager";

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            homeModule = lib.mkOption {
              description = "Home-manager modules for the user";
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = "/home/module.nix";
            };
          };
        }
      );
      default = { };
    };
  };

  # System level user settings
  config = {
    # Home Manager Settings
    home-manager = lib.mkIf cfg.enableHM {
      users = lib.mkMerge (
        builtins.map (user: {
          ${user} = import cfg.users.${user}.homeModule;
        }) (builtins.attrNames cfg.users)
      );
    };
  };
}
