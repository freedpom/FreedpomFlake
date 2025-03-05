{
  lib,
  config,
  inputs,
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
    environment.persistence."/nix/persist" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/tailscale"
        "/etc/NetworkManager/system-connections"
      ];
      files = [
        "/etc/machine-id"
      ];
    };

    imports = lib.optional cfg.enable [ inputs.impermanence.nixosModules.impermanence ];

  };
}
