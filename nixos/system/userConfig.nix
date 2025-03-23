{ config, lib, ... }:
let

  cfg = config.ff.userConfig;

in

{
  options.ff.userConfig = {
    mutableUsers = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow users to be modified from the running system";
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            role = lib.mkOption {
              type = lib.types.enum [
                "user" # Normal user
                "admin" # System administrator
                "system" # System user, used for services and containers
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
              type = lib.types.number;
              default = "";
              example = "1000";
              description = "user id of the specified user";
            };
            hashedPassword = lib.mkOption {
              type = lib.types.str;
              default = "$6$i8pqqPIplhh3zxt1$bUH178Go8y5y6HeWKIlyjMUklE2x/8Vy9d3KiCD1WN61EtHlrpWrGJxphqu7kB6AERg6sphGLonDeJvS/WC730"; # "password"
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
              description = "extra groups needed by user";
            };
          };
        }
      );
      default = { };
    };
  };
  config.users = {
    inherit (cfg) mutableUsers;
    users = lib.mkMerge (
      builtins.map (user: {
        ${user} = {
          inherit (cfg.users.${user}) uid hashedPassword;
          isSystemUser = lib.mkIf (cfg.users.${user}.role == "system") true;

          isNormalUser = lib.mkIf (
            (cfg.users.${user}.role == "user") || (cfg.users.${user}.role == "admin")
          ) true;

          extraGroups =
            cfg.users.${user}.extraGroups
            ++ lib.optionals (cfg.users.${user}.role == "admin") [ "wheel" ]
            ++ lib.optionals (lib.elem "base" cfg.users.${user}.tags) [ "networkmanager" ];
        };
      }) (builtins.attrNames cfg.users)
    );
  };
}
