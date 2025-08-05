{
  config,
  lib,
  ...
}: let
  cfg = config.ff.services.openssh;
in {
  # Configuration options for OpenSSH service
  options.ff.services.openssh = {
    enable = lib.mkEnableOption "Enable the OpenSSH server";
  };

  config = lib.mkIf cfg.enable {
    # OpenSSH server configuration
    services.openssh = {
      # Enable OpenSSH daemon
      enable = true;

      # Security-hardened host keys
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          rounds = 100;
          type = "ed25519";
        }
      ];
    };
  };
}
