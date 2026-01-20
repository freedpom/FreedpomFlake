{
  flake.nixosModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.system.locale;
    in
    {
      options.freedpom.system.locale = {
        enable = lib.mkEnableOption "System locale and timezone configuration";

        defaultLocale = lib.mkOption {
          type = lib.types.str;
          default = "en_US.UTF-8";
          description = "Default system locale";
        };

        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "America/New_York";
          description = "System time zone";
        };
      };

      config = lib.mkIf cfg.enable {
        i18n.defaultLocale = cfg.defaultLocale;
        time.timeZone = cfg.timeZone;
      };
    };
}
