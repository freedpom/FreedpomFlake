{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.security.sops;
in
{
  options.ff.security.sops = {
    enable = lib.mkEnableOption "Enable declarative secrets using sops-nix";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = /persist/secrets/general.yaml;
      age = {
        generateKey = true;
      };
      secrets = {
        "qpassword" = {
          neededForUsers = true;
        };
      };
    };
  };
}
