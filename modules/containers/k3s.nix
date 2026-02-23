{
  flake.nixosModules.containers =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.k3s;
    in
    {
      options.freedpom.k3s = {
        enable = lib.mkEnableOption "k3s";
      };

      config = lib.mkIf cfg.enable {
        services.k3s = {
          enable = true;
          role = "server";
          clusterInit = true;
          images = [ pkgs.grafana-oci ];
        };

        environment.systemPackages = with pkgs; [
          kubectl
          k9s
        ];
      };
    };
}
