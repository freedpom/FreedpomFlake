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
      packages.postgresql-oci = n2c.buildImage { # nix run .#postgresql-oci.copyToPodman
        name = "postgresql";
        tag = "latest";
        meta = with pkgs.lib; {
          description = "Open-source object-relational database system (OCI image)";
          longDescription = ''
            PostgreSQL is a powerful open source object-relational database system
            with over 35 years of active development. It is known for its reliability,
            feature completeness, and performance.

            This package provides PostgreSQL as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://www.postgresql.org/";
          changelog = "https://www.postgresql.org/docs/release/";
          license = licenses.postgresql;
          platforms = platforms.linux;
        };

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
          workingDir = "/var/lib/postgresql";

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

          stopSignal = "SIGTERM";

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

          labels = {
            "org.opencontainers.image.title" = "PostgreSQL";
            "org.opencontainers.image.description" = "Open-source object-relational database system";
            "org.opencontainers.image.vendor" = "Freedpom";
            "org.opencontainers.image.licenses" = "PostgreSQL";
          };
        };
      };
    };
}
