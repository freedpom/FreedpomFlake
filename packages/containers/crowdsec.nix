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
      packages.crowdsec-oci = n2c.buildImage {
        name = "crowdsec";
        meta = with pkgs.lib; {
          description = "Open-source security engine (OCI image)";
          longDescription = ''
            CrowdSec is a free, open-source and collaborative security engine.
            It detects malicious IPs and behaviors, and blocks them at the
            firewall, proxy, or application level.

            This package provides CrowdSec as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://crowdsec.net/";
          changelog = "https://github.com/crowdsecurity/crowdsec/releases";
          license = licenses.mit;
          platforms = platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "crowdsec-root" [ pkgs.crowdsec ])
          (base.mkUser "crowdsec" "101" "101" "/" "/bin/sh")
        ];

        perms = [
          {
            path = "/var/lib/crowdsec/data";
            regex = ".*";
            mode = "0755";
          }
          {
            path = "/etc/crowdsec";
            regex = ".*";
            mode = "0755";
          }
        ];

        config = {
          user = "crowdsec";
          workingDir = "/";

          env = [
            "COLLECTIONS=crowdsecurity/nginx"
            "GID=1000"
          ];

          entrypoint = [ "${pkgs.crowdsec}/bin/crowdsec" ];
          cmd = [ "--no-cs" ];

          exposedPorts = {
            "8080/tcp" = { };
          };

          volumes = {
            "/var/log/nginx" = { };
            "/var/lib/crowdsec/data" = { };
            "/etc/crowdsec" = { };
          };

          healthcheck = {
            test = [
              "CMD-SHELL"
              "${pkgs.crowdsec}/bin/crowdsec -c /etc/crowdsec/config.yaml -t || exit 1"
            ];
            interval = "30s";
            timeout = "10s";
            retries = 3;
            startPeriod = "30s";
          };

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "CrowdSec";
            "org.opencontainers.image.description" = "Open-source security engine";
            "org.opencontainers.image.licenses" = "MIT";
          };
        };
      };
    };
}
