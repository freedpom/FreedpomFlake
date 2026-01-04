{
  imports = [
    ./hyprland
  ];

  flake.homeModules.windowManagers =
    {
      config,
      lib,
      pkgs,
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
      config = lib.mkIf cfg.autoStart {
        systemd.user.services.uwsm-start = {
          Unit = {
            Description = "Start uwsm session";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.bash}/bin/bash -lc ''if uwsm check may-start && uwsm select; then exec uwsm start default; fi''";
          };
        };
      };
    };
}
