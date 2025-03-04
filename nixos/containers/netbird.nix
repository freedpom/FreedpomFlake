{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.netbird;
in
{
  options.ff.netbird = {
    enable = lib.mkEnableOption "Enable";
  };

  config = lib.mkIf cfg.containers.enable {
    containers.netbird = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      hostAddress6 = "fc00::1";
      localAddress6 = "fc00::2";
      config =
        { lib, ... }:
        {

          services.netbird = {
            enable = true;
            server = {
              enable = true;
            };
          };

          system.stateVersion = "24.11";

          networking = {
            firewall = {
              enable = true;
              allowedTCPPorts = [ 80 ];
            };
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          services.resolved.enable = true;

        };
    };
  };
}
