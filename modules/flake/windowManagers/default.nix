{
  imports = [
    ./hyprland
  ];

  flake.homeModules.windowManagers =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.ff.windowManagers;
    in
    {
      options.ff.windowManagers = {
        autoStart = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      config = {
        systemd.user.services.uwsm-start = lib.mkIf cfg.autoStart {
          Unit = {
            Description = "Start UWSM.";
            After = "graphical-session-pre.target";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            Type = "simple";
            Environment = "PATH=/run/wrappers/bin:/var/lib/flatpak/exports/bin:/nix/profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
            ExecStartPre = "/run/current-system/sw/bin/uwsm check may-start";
            ExecStart = "/run/current-system/sw/bin/uwsm select";
            Restart = "no";
          };
        };
      };
    };
}
