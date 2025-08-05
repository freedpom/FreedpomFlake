{
  lib,
  config,
  ...
}: let
  cfg = config.ff.system.performance;
in {
  options.ff.system.performance = {
    enable = lib.mkEnableOption "Enable performance tweaks ";
  };

  config = lib.mkIf cfg.enable {
    services.irqbalance.enable = true;
    systemd = {
      watchdog = {
        runtimeTime = "30s";
        rebootTime = "45s";
      };
      coredump.enable = false;
    };
  };
}
