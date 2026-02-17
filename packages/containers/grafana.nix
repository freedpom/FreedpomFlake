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
      packages.grafana-oci = n2c.buildImage {
        name = "grafana";
        meta = with pkgs.lib; {
          description = "Observability platform for metrics, logs, and traces (OCI image)";
          longDescription = ''
            Grafana is an open-source observability platform for querying, visualizing,
            alerting, and exploring metrics, logs, and traces. It integrates with various
            data sources including Prometheus, InfluxDB, and Elasticsearch.

            This package provides Grafana as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://grafana.com/";
          changelog = "https://github.com/grafana/grafana/releases";
          license = licenses.agpl3Only;
          platforms = platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "grafana-root" [
            pkgs.grafana
            pkgs.curl
          ])
          base.rootUser
          (pkgs.runCommand "grafana-setup" { } ''
                        mkdir -p $out/var/lib/grafana
                        mkdir -p $out/var/log/grafana
                        mkdir -p $out/etc/grafana/provisioning/datasources
                        mkdir -p $out/etc/grafana/provisioning/dashboards
                        # Create minimal config
                        cat > $out/etc/grafana/grafana.ini << 'EOF'
            [paths]
            data = /var/lib/grafana
            logs = /var/log/grafana
            plugins = /var/lib/grafana/plugins
            provisioning = /etc/grafana/provisioning
            EOF
          '')
        ];

        config = {
          user = "root";
          workingDir = "/var/lib/grafana";

          entrypoint = [ "${pkgs.grafana}/bin/grafana" ];

          cmd = [
            "server"
            "--config=/etc/grafana/grafana.ini"
            "--homepath=${pkgs.grafana}/share/grafana"
            "--packaging=nix"
          ];

          exposedPorts = {
            "3000/tcp" = { };
          };

          volumes = {
            "/var/lib/grafana" = { };
            "/var/log/grafana" = { };
            "/etc/grafana" = { };
          };

          healthcheck = {
            test = [
              "CMD-SHELL"
              "${pkgs.curl}/bin/curl -f http://localhost:3000/api/health || exit 1"
            ];
            interval = "30s";
            timeout = "10s";
            retries = 3;
            startPeriod = "30s";
          };

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "Grafana";
            "org.opencontainers.image.description" = "Observability platform for metrics, logs, and traces";
            "org.opencontainers.image.licenses" = "AGPL-3.0-only";
          };
        };
      };
    };
}
