{ lib, config, ... }:
let
  cfg = config.ff.services.openssh;
in
{
  options.ff.services.openssh = {
    enable = lib.mkEnableOption "Enable the openssh";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
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
