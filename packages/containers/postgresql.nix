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
      packages.postgresql-oci = n2c.buildImage {
        # nix run .#postgresql-oci.copyToPodman
        name = "postgresql";
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
          (base.mkAppEnv "postgres-root" [
            pkgs.postgresql_16
            pkgs.util-linux
          ])
          (base.mkUser "postgres" "999" "999" "/var/lib/postgresql" "/bin/sh")
          (pkgs.runCommand "postgresql-dirs" { } ''
            mkdir -p $out/run/postgresql
          '')
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
            "PGSOCKET_DIR=/tmp"
          ];

          entrypoint = [
            "${pkgs.bash}/bin/bash"
          ];

          cmd = [
            "-c"
            ''
              # Create directories
              mkdir -p /var/lib/postgresql/data

              # Create and initialize data directory if it doesn't exist
              if [ ! -d '/var/lib/postgresql/data/base' ]; then
                ${pkgs.postgresql_16}/bin/initdb -D /var/lib/postgresql/data -U $POSTGRES_USER
              fi

              # Start PostgreSQL
              exec ${pkgs.postgresql_16}/bin/postgres -D /var/lib/postgresql/data
            ''
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

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "PostgreSQL";
            "org.opencontainers.image.description" = "Open-source object-relational database system";
            "org.opencontainers.image.licenses" = "PostgreSQL";
          };
        };
      };
    };
}
