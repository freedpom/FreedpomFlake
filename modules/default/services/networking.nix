{
  flake.nixosModules.default =
    {
      lib,
      config,
      hostname,
      ...
    }:
    let
      cfg = config.freedpom.services.networking;
    in
    {
      options.freedpom.services.networking = {
        containers.enable = lib.mkEnableOption "Network configuration with NAT for containers and privacy-focused NetworkManager settings";
        mesh = lib.mkEnableOption "Mesh networking via Tailscale for secure peer-to-peer connectivity";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = hostname;
          description = "System hostname";
        };

        hostId = lib.mkOption {
          type = lib.types.str;
          default = "00000000";
          description = "System host ID for ZFS and other filesystems";
        };
      };

      config = lib.mkIf (cfg.containers.enable || cfg.hostName != null) {
        networking = {
          hostName = lib.mkIf (cfg.hostName != null) cfg.hostName;
          inherit (cfg) hostId;

          nftables.enable = lib.mkIf cfg.containers.enable true;

          firewall = lib.mkIf cfg.containers.enable {
            enable = true;
            allowedTCPPorts = [ ];
            allowedUDPPorts = [ ];
          };

          nat = lib.mkIf cfg.containers.enable {
            enable = true;
            # Lazy IPv6 connectivity for the container
            enableIPv6 = true;
            externalInterface = "en01";
            internalInterfaces = [ "ve-*" ];
          };

          # NetworkManager settings
          networkmanager = lib.mkIf cfg.containers.enable {
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
    };
}
