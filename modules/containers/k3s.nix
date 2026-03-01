{
  flake.nixosModules.containers =
    {
      lib,
      config,
      pkgs,
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
          images = [ pkgs.grafana-oci ];
        };
        networking.firewall.allowedTCPPorts = [
          6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
        ];

        environment.systemPackages = with pkgs; [
          kubectl
          k9s
        ];
      };
    };
}
