{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.ff.containers;
in
{
  options.ff.containers = {
    enable = lib.mkEnableOption "Enable";
  };
  config = lib.mkIf cfg.enable {
    virtualisation = {
      oci-containers.backend = "podman";
      containers.enable = true;

      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

    };
    environment.systemPackages = with pkgs; [
      dive
      podman-tui
    ];
  };
}
