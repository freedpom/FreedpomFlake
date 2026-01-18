{
  flake.nixosModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.services.containers.caddy;
    in
    {
      options.freedpom.services.containers.caddy = {
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
    };
}
