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
          (base.mkUsersWithRoot "grafana" "472" "472" "/var/lib/grafana" "/bin/sh")
          (pkgs.runCommand "grafana-setup" { } ''
                        mkdir -p $out/var/lib/grafana
                        mkdir -p $out/var/log/grafana
                        mkdir -p $out/etc/grafana/provisioning/datasources
                        mkdir -p $out/etc/grafana/provisioning/dashboards
                        # Create entrypoint script
                        mkdir -p $out/usr/local/bin
                        cat > $out/usr/local/bin/start-grafana << 'EOF'
            #!/bin/sh
            chown -R grafana:grafana /var/lib/grafana /var/log/grafana /etc/grafana
            mkdir -p /var/lib/grafana/plugins
            mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /etc/grafana/provisioning/notifiers /etc/grafana/provisioning/alerting
            if [ ! -f /etc/grafana/grafana.ini ]; then
              echo "[paths]" > /etc/grafana/grafana.ini
              echo "data = /var/lib/grafana" >> /etc/grafana/grafana.ini
              echo "logs = /var/log/grafana" >> /etc/grafana/grafana.ini
              echo "plugins = /var/lib/grafana/plugins" >> /etc/grafana/grafana.ini
              echo "provisioning = /etc/grafana/provisioning" >> /etc/grafana/grafana.ini
            fi
            exec su -s /bin/sh grafana -c 'GF_PATHS_CONFIG=/etc/grafana/grafana.ini GF_PATHS_DATA=/var/lib/grafana GF_PATHS_LOGS=/var/log/grafana GF_PATHS_PLUGINS=/var/lib/grafana/plugins GF_PATHS_PROVISIONING=/etc/grafana/provisioning GF_SERVER_HTTP_PORT=3000 exec ${pkgs.grafana}/bin/grafana server --config=/etc/grafana/grafana.ini --homepath=${pkgs.grafana}/share/grafana --packaging=nix'
            EOF
                        chmod +x $out/usr/local/bin/start-grafana
          '')
        ];

        config = {
          user = "root";
          workingDir = "/var/lib/grafana";

          entrypoint = [ "/usr/local/bin/start-grafana" ];

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
              "curl -f http://localhost:3000/api/health || exit 1"
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
