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
      packages.caddy-oci = n2c.buildImage {
        name = "caddy";
        meta = with pkgs.lib; {
          description = "Web server with automatic HTTPS (OCI image)";
          longDescription = ''
            Caddy 2 is a powerful, enterprise-ready, open source web server with
            automatic HTTPS written in Go. It simplifies TLS certificate management
            through automatic Let's Encrypt integration.

            This package provides Caddy as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://caddyserver.com/";
          changelog = "https://github.com/caddyserver/caddy/releases";
          license = licenses.asl20;
          platforms = platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "caddy-root" [ pkgs.caddy ])
          (base.mkUser "caddy" "100" "100" "/srv" "/bin/sh")
        ];

        perms = [
          {
            path = "/data";
            regex = ".*";
            mode = "0755";
          }
          {
            path = "/config";
            regex = ".*";
            mode = "0755";
          }
        ];

        config = {
          user = "caddy";
          workingDir = "/srv";

          env = [
            "CADDY_INGRESS_HOSTNAMES=localhost"
            "CADDY_INGRESS_PORTS=80,443"
          ];

          entrypoint = [ "${pkgs.bash}/bin/bash" ];

          cmd = [
            "-c"
            ''
              # Create config directory
              mkdir -p /etc/caddy

              # Default simple config if not provided
              if [ ! -f /etc/caddy/Caddyfile ]; then
                echo ':8080 {
                  respond "Hello from Caddy!"
                }' > /etc/caddy/Caddyfile
              fi

              exec ${pkgs.caddy}/bin/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
            ''
          ];

          exposedPorts = {
            "80/tcp" = { };
            "443/tcp" = { };
            "443/udp" = { };
          };

          volumes = {
            "/etc/caddy" = { };
            "/srv" = { };
            "/data" = { };
            "/config" = { };
          };

          healthcheck = {
            test = [
              "CMD-SHELL"
              "${pkgs.caddy}/bin/caddy version || exit 1"
            ];
            interval = "30s";
            timeout = "10s";
            retries = 3;
            startPeriod = "10s";
          };

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "Caddy";
            "org.opencontainers.image.description" = "Web server with automatic HTTPS";
            "org.opencontainers.image.licenses" = "Apache-2.0";
          };
        };
      };
    };
}
