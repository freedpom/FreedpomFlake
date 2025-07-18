{
  inputs,
  config,
  lib,
  ...
}:
let

  cfg = config.ff.userConfig;

  baseGroups = [ "networkmanager" ];

  adminGroups = [ "wheel" ];

in

{
  options.ff.userConfig = {

    mutableUsers = lib.mkEnableOption "Allow users to be modified from the running system";

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            role = lib.mkOption {
              type = lib.types.enum [
                "user" # Normal user
                "admin" # System administrator
                "system" # Services and containers
              ];
              default = "user";
              example = "system";
              description = "Configure system users.";
            };

            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = "gaming";
              description = "";
            };

            uid = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              example = 1000;
              description = "user id of the specified user";
            };

            hashedPassword = lib.mkOption {
              type = lib.types.str;
              example = "$6$i8pqqPIplhh3zxt1$bUH178Go8y5y6HeWKIlyjMUklE2x/8Vy9d3KiCD1WN61EtHlrpWrGJxphqu7kB6AERg6sphGLonDeJvS/WC730";
              description = "hashed password of the specified user";
            };

            extraGroups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [
                "audio"
                "video"
              ];
              description = "Extra groups needed by the user";
            };

            home = {
              type = lib.types.nullOr lib.types.str;
            };

            homeModule = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Home-manager modules for the user";
            };
          };
        }
      );
      default = { };
    };
  };

  # System level user settings
  config = {
    users = {
      inherit (cfg) mutableUsers;
      users = lib.mkMerge (
        builtins.map (user: {
          ${user} = {

            inherit (cfg.users.${user}) hashedPassword;
            uid = lib.mkIf (cfg.users.${user}.uid != null) cfg.users.${user}.uid;

            isSystemUser = lib.mkIf (cfg.users.${user}.role == "system") true;

            isNormalUser = lib.mkIf (
              (cfg.users.${user}.role == "user") || (cfg.users.${user}.role == "admin")
            ) true;

            extraGroups =
              cfg.users.${user}.extraGroups
              ++ lib.optionals (cfg.users.${user}.role == "admin") adminGroups
              ++ lib.optionals (lib.elem "base" cfg.users.${user}.tags) baseGroups;

          };
        }) (builtins.attrNames cfg.users)
      );
    };

    # Home Manager Settings
    home-manager = {
      backupFileExtension = "bk";
      extraSpecialArgs = {
        inherit inputs;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
