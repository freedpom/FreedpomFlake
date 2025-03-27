{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.network;
in
{
  options.ff.network = {
    containers.enable = lib.mkEnableOption "Enable";
    mesh = lib.mkEnableOption "Enable mesh";
  };

  config = lib.mkIf cfg.containers.enable {
    networking = {
      nat = {
        enable = true;
        internalInterfaces = [ "ve-+" ];
        externalInterface = "en01";
        # Lazy IPv6 connectivity for the container
        enableIPv6 = true;
      };
      firewall = {
        enable = lib.mkEnableOption;
        preset = {
          type = lib.types.enum [
            "pc"
            "server"
            "all" # enabling firewall blocks all traffic by default, hence this preset not being mentioned
          ];
          default = "desktop";
        };
      };
    };
    services.tailscale.enable = cfg.mesh;
  };
}
