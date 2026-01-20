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
    in
    {
      packages.container-postgresql = n2c.buildImage {
        name = "postgresql";

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (pkgs.buildEnv {
            name = "postgres-root";
            paths = [
              pkgs.postgresql_16
              pkgs.glibc
            ];
            pathsToLink = [
              "/bin"
            ];
          })
        ];

        perms = [
          {
            path = "/var/lib/postgresql";
            regex = ".*";
            mode = "0700";
          }
        ];

        config = {
          user = "postgres";

          env = [
            "PGDATA=/var/lib/postgresql/data"
            "POSTGRES_DB=authentik"
            "POSTGRES_USER=authentik"
          ];

          entrypoint = [
            "${pkgs.postgresql_16}/bin/postgres"
          ];

          cmd = [
            "-D"
            "/var/lib/postgresql/data"
          ];

          exposedPorts = {
            "5432/tcp" = { };
          };

          volumes = {
            "/var/lib/postgresql/data" = { };
          };

          healthcheck = {
            test = [
              "CMD-SHELL"
              "${pkgs.postgresql_16}/bin/pg_isready -d $POSTGRES_DB -U $POSTGRES_USER"
            ];
            interval = "30s";
            timeout = "5s";
            retries = 5;
            startPeriod = "20s";
          };
        };
      };
    };
}
