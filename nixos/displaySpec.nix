{ lib, ... }:
{
  options = {
    videoPorts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            resolution = {
              width = lib.mkOption {
                type = lib.types.int;
                default = 1920;
                description = "Display width in pixels";
              };
              height = lib.mkOption {
                type = lib.types.int;
                default = 1080;
                description = "Display height in pixels";
              };
            };
          };
        }
      );
      default = { };
      description = "Configuration for video ports";
    };
  };
}
