{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.persistence;
in
{
  options.ff.system.persistence = {
    enable = lib.mkEnableOption "Enable system persistence";
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."${config.hostConf.persistMain}" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
      ];
      files = [
        "/etc/machine-id"
      ];
    };

  };
}
