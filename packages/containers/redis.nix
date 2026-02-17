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
      packages.redis-oci = n2c.buildImage {
        name = "redis";
        meta = with pkgs.lib; {
          description = "In-memory key-value store and cache (OCI image)";
          longDescription = ''
            Redis is an in-memory data structure store, used as a database, cache, and message broker.
            It supports various data structures such as strings, hashes, lists, sets, sorted sets
            with range queries, bitmaps, hyperloglogs, geospatial indexes, and streams.

            This package provides Redis as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://redis.io/";
          changelog = "https://raw.githubusercontent.com/redis/redis/unstable/00-RELEASENOTES";
          license = pkgs.lib.licenses.bsd3;
          platforms = pkgs.lib.platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "redis-root" [
            pkgs.redis
          ])
          base.rootUser
          (pkgs.runCommand "redis-setup" { } ''
            mkdir -p $out/data
            mkdir -p $out/etc/redis
          '')
        ];

        config = {
          user = "root";
          workingDir = "/data";

          env = [
            "REDIS_PORT=6379"
          ];

          entrypoint = [ "${pkgs.bash}/bin/bash" ];

          cmd = [
            "-c"
            ''
              ${pkgs.redis}/bin/redis-server \
                --port 6379 \
                --dir /data \
                --appendonly no \
                --protected-mode no \
                --bind 0.0.0.0
            ''
          ];

          exposedPorts = {
            "6379/tcp" = { };
          };

          volumes = {
            "/data" = { };
          };

          stopSignal = "SIGTERM";

          healthcheck = {
            test = [
              "CMD-SHELL"
              "${pkgs.redis}/bin/redis-cli ping || exit 1"
            ];
            interval = "30s";
            timeout = "10s";
            retries = 3;
            startPeriod = "10s";
          };

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "Redis";
            "org.opencontainers.image.description" = "In-memory key-value store and cache";
            "org.opencontainers.image.licenses" = "BSD-3-Clause";
          };
        };
      };
    };
}
