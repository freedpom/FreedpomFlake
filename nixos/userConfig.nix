{ lib, ... }:
{

  options.userConf = {
    userType = lib.mkOption {
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
      type = lib.types.listOf lib.types.enum [
        # Tags enabling groups for userspace functionality
      ];
      default = "";
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
      type = lib.types.string;
      default = "";
      example = "$6$i8pqqPIplhh3zxt1$bUH178Go8y5y6HeWKIlyjMUklE2x/8Vy9d3KiCD1WN61EtHlrpWrGJxphqu7kB6AERg6sphGLonDeJvS/WC730";
      description = "hashed password of the specified user";
    };
    extraGroups = lib.mkOption {
      type = lib.types.list;
      default = [ ];
      example = [
        "audio"
        "video"
      ];
      description = "extra groups needed by user";
    };
  };
}
