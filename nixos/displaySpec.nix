{ lib, ... }:
{
  options = {
    ff.hardware.displays = lib.mkOption {
      description = "Hardware Display Configuration";
      type = lib.types.listOf lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          refreshRate = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
          resWidth = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
          resHeight = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
          ownedWorkspaces = lib.mkOption {
            type = lib.types.nullOr lib.types.listOf lib.types.int;
            default = null;
          };
        };
      };
    };
  };

}
