{
  flake.modules.hjem.desktop =
    { config, lib, ... }:
    let
      cfg = config.freedpom.desktop.cursors;
    in
    {
      options.freedpom.desktop.cursors = {
        enable = lib.mkEnableOption "Enable cursor theming";
        xcursor = {
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

        hyprcursor = {
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
      config = {
        xdg.data.files = {
          "icons/${cfg.hyprcursor.theme.name}-hyprcursor" = lib.mkIf (cfg.hyprcursor.theme.package != null) {
            source = cfg.hyprcursor.theme.package;
          };

          "icons/${cfg.xcursor.theme.name}" = lib.mkIf (cfg.xcursor.theme.package != null) {
            source = "${cfg.xcursor.theme.package}/share/icons/${cfg.xcursor.theme.name}";
          };
        };
      };
    };
}
