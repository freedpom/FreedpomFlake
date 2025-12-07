{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.containers.caddy;
in
{
  options.ff.containers.caddy = {
    enable = lib.mkEnableOption "Enable";
  };
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      caddy = {
        image = "caddy:2.10.2";
        autoStart = true;
      };
    };
  };
}
