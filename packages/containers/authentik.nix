{
  perSystem =
    {
      pkgs,
      inputs',
      base,
      ...
    }:
    let
      n2c = inputs'.nix2container.packages.nix2container;

      authentikRoot = pkgs.buildEnv {
        name = "authentik-root";
        paths = [
          pkgs.authentik
          pkgs.python3
          pkgs.openssl
          pkgs.glibc
        ];
        pathsToLink = [
          "/bin"
        ];
      };

      common = {
        env = [
          "AUTHENTIK_POSTGRESQL__HOST=postgresql"
          "AUTHENTIK_POSTGRESQL__NAME=authentik"
          "AUTHENTIK_POSTGRESQL__USER=authentik"
          "AUTHENTIK_DISABLE_UPDATE_CHECK=true"
        ];

        volumes = {
          "/data" = { };
          "/templates" = { };
        };
      };
    in
    {
      packages = {
        container-authentik-server = n2c.buildImage {
          name = "authentik-server";

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            authentikRoot
          ];

          config = common // {
            entrypoint = [ "${pkgs.authentik}/bin/authentik" ];
            cmd = [ "server" ];

            exposedPorts = {
              "9000/tcp" = { };
              "9443/tcp" = { };
            };
          };
        };

        container-authentik-worker = n2c.buildImage {
          name = "authentik-worker";

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            authentikRoot
          ];

          config = common // {
            user = "0";

            entrypoint = [ "${pkgs.authentik}/bin/authentik" ];
            cmd = [ "worker" ];

            volumes = common.volumes // {
              "/var/run/docker.sock" = { };
              "/certs" = { };
            };
          };
        };
      };
    };
}
