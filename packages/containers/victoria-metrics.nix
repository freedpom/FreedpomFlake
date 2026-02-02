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
      packages = {
        victoriametrics-oci = n2c.buildImage {
          name = "victoriametrics-oci";
          meta = with pkgs.lib; {
            description = "Time series database (OCI image)";
            longDescription = ''
              VictoriaMetrics is a fast, cost-effective and scalable monitoring solution
              and time series database. It can be used as a long-term storage for
              Prometheus or as a standalone monitoring system.

              This package provides VictoriaMetrics as an OCI-compatible container image,
              suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
            '';
            homepage = "https://victoriametrics.com/";
            changelog = "https://github.com/VictoriaMetrics/VictoriaMetrics/releases";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vm-root" [ pkgs.victoriametrics ])
            (base.mkUser "victoria-metrics" "103" "103" "/" "/bin/sh")
          ];

          perms = [
            {
              path = "/storage";
              regex = ".*";
              mode = "0755";
            }
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${pkgs.victoriametrics}/bin/victoria-metrics" ];
            cmd = [
              "--storageDataPath=/storage"
              "--httpListenAddr=:8428"
              "--retentionPeriod=100y"
            ];

            exposedPorts = {
              "8428/tcp" = { };
            };

            volumes = {
              "/storage" = { };
            };

            stopSignal = "SIGTERM";

            healthcheck = {
              test = [
                "CMD-SHELL"
                "curl -f http://localhost:8428/health || exit 1"
              ];
              interval = "30s";
              timeout = "10s";
              retries = 3;
              startPeriod = "30s";
            };

            labels = base.commonLabels // {
              "org.opencontainers.image.title" = "VictoriaMetrics";
              "org.opencontainers.image.description" = "Time series database";
              "org.opencontainers.image.licenses" = "Apache-2.0";
            };
          };
        };

        vmagent-oci = n2c.buildImage {
          name = "vmagent-oci";
          meta = with pkgs.lib; {
            description = "Metrics collection agent (OCI image)";
            longDescription = ''
              VM agent is a tiny but brave agent which helps you collect metrics
              from various sources and store them to VictoriaMetrics or any other
              Prometheus-compatible storage systems.

              This package provides VM agent as an OCI-compatible container image,
              suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
            '';
            homepage = "https://victoriametrics.com/products/vmagent/";
            changelog = "https://github.com/VictoriaMetrics/VictoriaMetrics/releases";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vmagent-root" [ pkgs.vmagent ])
            (base.mkUser "victoria-metrics" "102" "102" "/" "/bin/sh")
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${pkgs.vmagent}/bin/vmagent" ];
            cmd = [
              "--promscrape.config=/etc/prometheus/prometheus.yml"
              "--remoteWrite.url=http://victoriametrics:8428/api/v1/write"
            ];

            exposedPorts = {
              "8429/tcp" = { };
            };

            volumes = {
              "/etc/prometheus" = { };
            };

            stopSignal = "SIGTERM";

            healthcheck = {
              test = [
                "CMD-SHELL"
                "curl -f http://localhost:8429/metrics || exit 1"
              ];
              interval = "30s";
              timeout = "10s";
              retries = 3;
              startPeriod = "10s";
            };

            labels = {
              "org.opencontainers.image.title" = "VM agent";
              "org.opencontainers.image.description" = "Metrics collection agent";
              "org.opencontainers.image.vendor" = "Freedpom";
              "org.opencontainers.image.source" = "https://github.com/freedpom/FreedpomFlake";
              "org.opencontainers.image.licenses" = "Apache-2.0";
            };
          };
        };
      };
    };
}
