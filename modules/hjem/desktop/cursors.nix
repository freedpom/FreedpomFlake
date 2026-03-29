{
  flake.modules.hjem.desktop.cursors = {lib, ... }: {
    options.freedpom.desktop.cursors = {
      xcursor = {
        enable = lib.mkEnableOption "Enable xcursor theming";
          size = lib.mkOption {
            type = lib.types.str;
            default = "24";
          };
          theme = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
            };
      };
        hyprcursor = {
          enable = lib.mkEnableOption "Enable hyprcursor theming";
          size = lib.mkOption {
            type = lib.types.str;
            default = "24";
          };
          theme = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "";
            };
            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
            };
          };
        };
    };
  };
  };
}
