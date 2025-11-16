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
      # Core network settings
      nftables.enable = true;

      # Firewall settings
      firewall = {
        enable = true;
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };

      # NAT configuration for containers
      nat = {
        enable = true;
        # Lazy IPv6 connectivity for the container
        enableIPv6 = true;
        externalInterface = "en01";
        internalInterfaces = [ "ve-*" ];
      };

      # NetworkManager settings
      networkmanager = {
        # Enable IPv6 privacy extensions in NetworkManager.
        connectionConfig."ipv6.ip6-privacy" = 2;
        ethernet.macAddress = "random";
        wifi = {
          macAddress = "random";
          scanRandMacAddress = true;
        };
      };
    };
    services.tailscale.enable = cfg.mesh;
  };
}
