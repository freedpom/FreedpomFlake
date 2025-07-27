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

    ephHome = lib.mkEnableOption "Setup persistent directories for an ephemeral home";

    directory = lib.mkOption {
      type = lib.types.str;
      default = "/nix/persist";
      description = "Directory where persistent data will be stored";
    };

    directories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra directories to be persisted";

    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra files to be persisted";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.persistence.${cfg.directory} = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/tailscale"
        "/etc/NetworkManager/system-connections"
      ] ++ cfg.directories;
      files = [
        "/etc/machine-id"
      ] ++ cfg.files;
    };

    # Systemd-tmpfiles rules for ephemeral /home
    systemd.tmpfiles.rules = lib.mkIf cfg.ephHome (
      lib.concatLists (
        builtins.map (user: [
          "d ${cfg.directory}/home/${user} 0755 ${user} ${config.users.users.${user}.group}"
        ]) (builtins.attrNames config.ff.userConfig.users)
      )
    );
  };
}
