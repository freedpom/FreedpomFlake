{
  flake.nixosModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.services.ananicy;
    in
    {
      # Configuration options for Ananicy service
      options.freedpom.services.ananicy = {
        enable = lib.mkEnableOption "Ananicy process management daemon with CachyOS rules for automatic CPU/IO priority optimization");
      };

      config = lib.mkIf cfg.enable {
        services = {
          ananicy = {
            enable = true;
            package = pkgs.ananicy-cpp;
            rulesProvider = pkgs.ananicy-rules-cachyos;
            settings = {
              # Ananicy run full system scan every "check_freq" seconds
              # supported values 0.01..86400
              # values which have sense: 1..60
              check_freq = 15;
              # Loglevel configuration
              # supported values: trace, debug, info, warn, error, critical
              loglevel = "info";
              log_applied_rule = false;

              # Module loading settings
              cgroup_load = true;
              rule_load = true;
              type_load = true;

              # Feature application settings
              apply_cgroup = true;
              apply_ionice = true;
              apply_latnice = true;
              apply_nice = true;
              apply_oom_score_adj = true;
              apply_sched = true;

              check_disks_schedulers = true;
            };
          };
        };
      };
    };
}
