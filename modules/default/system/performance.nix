{
  flake.nixosModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.system.performance;
    in
    {
      options.freedpom.system.performance = {
        enable = lib.mkEnableOption "Enable performance tweaks ";
      };

      config = lib.mkIf cfg.enable {
        services.irqbalance.enable = true;
        systemd = {
          settings.Manager = {
            RuntimeWatchdogSec = "30s";
            RebootWatchdogSec = "45s";
          };
          coredump.enable = false;
        };
      };
    };
}