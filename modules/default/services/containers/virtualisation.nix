{
  flake.nixosModules.default =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.services.containers;
    in
    {
      options.freedpom.services.containers = {
        enable = lib.mkEnableOption "Podman container runtime with Docker compatibility and included management tools";
      };

      config = lib.mkIf cfg.enable {
        virtualisation = {
          oci-containers.backend = "podman";
          containers.enable = true;

          podman = {
            enable = true;
            dockerCompat = true;
            defaultNetwork.settings.dns_enabled = true;
          };

        };
        environment.systemPackages = with pkgs; [
          dive
          podman-tui
        ];
      };
    };
}
