{
  config,
  lib,
  ...
}: let
  cfg = config.ff.netbird;
in {
  options.ff.netbird = {
    enable = lib.mkEnableOption "Enable";
  };

  config = lib.mkIf cfg.enable {
    # Container Configuration
    containers.netbird = {
      autoStart = true;
      privateNetwork = true;

      # Network Addresses
      hostAddress = "192.168.100.10";
      hostAddress6 = "fc00::1";
      localAddress = "192.168.100.11";
      localAddress6 = "fc00::2";
      # Container Internal Configuration
      config = {lib, ...}: {
        # Networking Configuration
        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [80];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        # Services
        services.netbird = {
          enable = true;
          server = {
            enable = true;
          };
        };

        services.resolved.enable = true;

        # System Configuration
        system.stateVersion = "24.11";
      };
    };
  };
}
