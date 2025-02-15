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
      defaultSopsFile = "${lib.getExe config.flake-root.package}/general.yaml";
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
