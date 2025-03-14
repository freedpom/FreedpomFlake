{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.ff.services.ananicy;
in
{
  options.ff.services.ananicy = {
    enable = lib.mkEnableOption "Enable the ananicy service for process resource management with customized rules and settings";
  };

  config = lib.mkIf cfg.enable {
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
      settings = {
        ## Ananicy 2.X configuration
        # Ananicy run full system scan every "check_freq" seconds
        # supported values 0.01..86400
        # values which have sense: 1..60
        check_freq = 15;

        # Disables functionality
        cgroup_load = true;
        type_load = true;
        rule_load = true;

        apply_nice = true;
        apply_latnice = true;
        apply_ionice = true;
        apply_sched = true;
        apply_oom_score_adj = true;
        apply_cgroup = true;

        # Loglevel
        # supported values: trace, debug, info, warn, error, critical
        loglevel = "info";

        # If enabled it does log task name after rule matched and got applied to the task
        log_applied_rule = false;

        # It tries to move realtime task to root cgroup to be able to move it to the ananicy-cpp controlled one
        # NOTE: may introduce issues, for example with polkit
        cgroup_realtime_workaround = lib.mkForce false;
      };
    };
  };
}
