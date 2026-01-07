{ ... }:
{
  imports = [
    ./monitors.nix
  ];
  flake.nixosModules.core =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.ff.core.services.openssh;
    in
    {
      options.ff.core.services.openssh = {
        enable = lib.mkEnableOption "Enable OpenSSH and Agent";
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
    };
  flake.homeModules.core =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.ff.core.services.openssh;
    in
    {
      options.ff.core.services.openssh = {
        enable = lib.mkEnableOption "Enable OpenSSH and Agent";
      };
      config = lib.mkIf cfg.enable {
        services.ssh-agent = {
          enable = true;
        };
        programs.ssh = {
          enable = true;
          matchBlocks = {
            "*" = {
              addKeysToAgent = "yes";
              compression = false;
              controlMaster = "no";
              controlPath = "${config.xdg.configHome}/ssh/master-%r@%n:%p";
              controlPersist = "no";
              forwardAgent = true;
              hashKnownHosts = false;
              identitiesOnly = true;
              serverAliveCountMax = 3;
              serverAliveInterval = 0;
              userKnownHostsFile = "${config.xdg.configHome}/ssh/known_hosts";
            };
            sk = {
              identityFile = [ "${config.xdg.configHome}/ssh/id_ed25519_key_sk" ];
            };
          };
        };
      };
    };
}
