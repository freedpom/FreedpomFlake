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
      nftables.enable = true;
      nat = {
        enable = true;
        internalInterfaces = [ "ve-*" ];
        externalInterface = "en01";
        # Lazy IPv6 connectivity for the container
        enableIPv6 = true;
      };

      firewall = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
        enable = true;
      };
      networkmanager = {
        ethernet.macAddress = "random";
        wifi = {
          macAddress = "random";
          scanRandMacAddress = true;
        };
        # Enable IPv6 privacy extensions in NetworkManager.
        connectionConfig."ipv6.ip6-privacy" = 2;
      };

    };
    services.tailscale.enable = cfg.mesh;
  };
}
