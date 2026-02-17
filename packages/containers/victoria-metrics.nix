{
  perSystem =
    {
      pkgs,
      inputs',
      base,
      lib,
      ...
    }:
    let
      n2c = inputs'.nix2container.packages.nix2container;

      # VictoriaMetrics cluster version derivation
      vmcluster = pkgs.buildGoModule rec {
        pname = "victoriametrics-cluster";
        version = "1.133.0";

        src = pkgs.fetchFromGitHub {
          owner = "VictoriaMetrics";
          repo = "VictoriaMetrics";
          rev = "v${version}-cluster";
          hash = "sha256-rdn7JHUEimRs4ayI7TILxgr8jtjf2MZM5Y8iI5lcjkc=";
        };

        vendorHash = null;

        subPackages = [
          "app/vmstorage"
          "app/vminsert"
          "app/vmselect"
        ];

        ldflags = [
          "-s"
          "-w"
          "-X github.com/VictoriaMetrics/VictoriaMetrics/lib/buildinfo.Version=${version}"
        ];

        env.GOTOOLCHAIN = "auto";

        postInstall = ''
          mv $out/bin/vmstorage $out/bin/vmstorage-cluster
          mv $out/bin/vminsert $out/bin/vminsert-cluster
          mv $out/bin/vmselect $out/bin/vmselect-cluster
        '';

        meta = with lib; {
          description = "VictoriaMetrics cluster version";
          homepage = "https://victoriametrics.com/";
          license = licenses.asl20;
          platforms = platforms.linux;
        };
      };

      # Common labels for all VM images
      vmLabels = base.commonLabels // {
        "org.opencontainers.image.vendor" = "Freedpom";
        "org.opencontainers.image.source" = "https://github.com/freedpom/FreedpomFlake";
        "org.opencontainers.image.licenses" = "Apache-2.0";
      };
    in
    {
      packages = {
        # Single-node VictoriaMetrics
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

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VictoriaMetrics";
              "org.opencontainers.image.description" = "Time series database";
            };
          };
        };

        # vmagent - Metrics collection agent
        vmagent-oci = n2c.buildImage {
          name = "vmagent-oci";
          meta = with pkgs.lib; {
            description = "Metrics collection agent (OCI image)";
            longDescription = ''
              VM agent is a tiny but brave agent which helps you collect metrics
              from various sources and store them to VictoriaMetrics or any other
              Prometheus-compatible storage systems.
            '';
            homepage = "https://victoriametrics.com/products/vmagent/";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vmagent-root" [ pkgs.victoriametrics ])
            (base.mkUser "victoria-metrics" "102" "102" "/" "/bin/sh")
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${pkgs.victoriametrics}/bin/vmagent" ];
            cmd = [
              "--promscrape.config=/etc/prometheus/prometheus.yml"
              "--remoteWrite.url=http://vmauth:8427/insert/0/prometheus/api/v1/write"
            ];

            exposedPorts = {
              "8429/tcp" = { };
            };

            volumes = {
              "/etc/prometheus" = { };
              "/vmagentdata" = { };
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

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VM Agent";
              "org.opencontainers.image.description" = "Metrics collection agent";
            };
          };
        };

        # vmstorage - Cluster storage component
        vmstorage-oci = n2c.buildImage {
          name = "vmstorage-oci";
          meta = with pkgs.lib; {
            description = "VictoriaMetrics cluster storage (OCI image)";
            longDescription = ''
              vmstorage is the storage component of VictoriaMetrics cluster.
              It stores the raw data and returns the queried data on the given time range.
            '';
            homepage = "https://victoriametrics.com/";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vmstorage-root" [ vmcluster ])
            (base.mkUser "victoria-metrics" "104" "104" "/" "/bin/sh")
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

            entrypoint = [ "${vmcluster}/bin/vmstorage-cluster" ];
            cmd = [
              "--storageDataPath=/storage"
            ];

            exposedPorts = {
              "8400/tcp" = { }; # vminsert port
              "8401/tcp" = { }; # vmselect port
              "8482/tcp" = { }; # http port
            };

            volumes = {
              "/storage" = { };
            };

            stopSignal = "SIGTERM";

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VM Storage";
              "org.opencontainers.image.description" = "Cluster storage component";
            };
          };
        };

        # vminsert - Cluster ingestion component
        vminsert-oci = n2c.buildImage {
          name = "vminsert-oci";
          meta = with pkgs.lib; {
            description = "VictoriaMetrics cluster insert (OCI image)";
            longDescription = ''
              vminsert is the insertion component of VictoriaMetrics cluster.
              It accepts incoming data and spreads it among vmstorage nodes.
            '';
            homepage = "https://victoriametrics.com/";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vminsert-root" [ vmcluster ])
            (base.mkUser "victoria-metrics" "105" "105" "/" "/bin/sh")
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${vmcluster}/bin/vminsert-cluster" ];
            cmd = [
              "--storageNode=vmstorage-1:8400"
              "--storageNode=vmstorage-2:8400"
            ];

            exposedPorts = {
              "8480/tcp" = { }; # http port
            };

            stopSignal = "SIGTERM";

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VM Insert";
              "org.opencontainers.image.description" = "Cluster ingestion component";
            };
          };
        };

        # vmselect - Cluster query component
        vmselect-oci = n2c.buildImage {
          name = "vmselect-oci";
          meta = with pkgs.lib; {
            description = "VictoriaMetrics cluster select (OCI image)";
            longDescription = ''
              vmselect is the query component of VictoriaMetrics cluster.
              It performs incoming queries and fetches the required data from vmstorage nodes.
            '';
            homepage = "https://victoriametrics.com/";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vmselect-root" [ vmcluster ])
            (base.mkUser "victoria-metrics" "106" "106" "/" "/bin/sh")
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${vmcluster}/bin/vmselect-cluster" ];
            cmd = [
              "--storageNode=vmstorage-1:8401"
              "--storageNode=vmstorage-2:8401"
              "--vmalert.proxyURL=http://vmalert:8880"
            ];

            exposedPorts = {
              "8481/tcp" = { }; # http port
            };

            stopSignal = "SIGTERM";

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VM Select";
              "org.opencontainers.image.description" = "Cluster query component";
            };
          };
        };

        # vmauth - Authentication and routing proxy
        vmauth-oci = n2c.buildImage {
          name = "vmauth-oci";
          meta = with pkgs.lib; {
            description = "VictoriaMetrics authentication proxy (OCI image)";
            longDescription = ''
              vmauth is a simple auth proxy and router for VictoriaMetrics.
              It can route requests to different backends based on the requested path
              and supports Basic Auth.
            '';
            homepage = "https://victoriametrics.com/products/vmauth/";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vmauth-root" [ pkgs.victoriametrics ])
            (base.mkUser "victoria-metrics" "107" "107" "/" "/bin/sh")
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${pkgs.victoriametrics}/bin/vmauth" ];
            cmd = [
              "--auth.config=/etc/auth.yml"
            ];

            exposedPorts = {
              "8427/tcp" = { };
            };

            volumes = {
              "/etc/auth.yml" = { };
            };

            stopSignal = "SIGTERM";

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VM Auth";
              "org.opencontainers.image.description" = "Authentication and routing proxy";
            };
          };
        };

        # vmalert - Alerting and recording rules
        vmalert-oci = n2c.buildImage {
          name = "vmalert-oci";
          meta = with pkgs.lib; {
            description = "VictoriaMetrics alerting (OCI image)";
            longDescription = ''
              vmalert executes alerting and recording rules against VictoriaMetrics.
              It works with all Prometheus-compatible data sources.
            '';
            homepage = "https://victoriametrics.com/products/vmalert/";
            license = licenses.asl20;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "vmalert-root" [ pkgs.victoriametrics ])
            (base.mkUser "victoria-metrics" "108" "108" "/" "/bin/sh")
          ];

          config = {
            user = "victoria-metrics";
            workingDir = "/";

            entrypoint = [ "${pkgs.victoriametrics}/bin/vmalert" ];
            cmd = [
              "--datasource.url=http://vmauth:8427/select/0/prometheus"
              "--remoteRead.url=http://vmauth:8427/select/0/prometheus"
              "--remoteWrite.url=http://vmauth:8427/insert/0/prometheus"
              "--notifier.url=http://alertmanager:9093/"
              "--rule=/etc/alerts/*.yml"
              "--external.url=http://127.0.0.1:3000"
            ];

            exposedPorts = {
              "8880/tcp" = { };
            };

            volumes = {
              "/etc/alerts" = { };
            };

            stopSignal = "SIGTERM";

            labels = vmLabels // {
              "org.opencontainers.image.title" = "VM Alert";
              "org.opencontainers.image.description" = "Alerting and recording rules";
            };
          };
        };
      };
    };
}
