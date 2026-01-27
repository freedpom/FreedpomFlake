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

      crowdsecRoot = pkgs.buildEnv {
        name = "crowdsec-root";
        paths = [
          pkgs.crowdsec
        ];
        pathsToLink = [
          "/bin"
        ];
      };
    in
    {
      packages.crowdsec-oci = n2c.buildImage {
        name = "crowdsec-oci";
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
          crowdsecRoot
        ];

        config = {
          user = "crowdsec:crowdsec";
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

          stopSignal = "SIGTERM";

          labels = {
            "org.opencontainers.image.title" = "CrowdSec";
            "org.opencontainers.image.description" = "Open-source security engine";
            "org.opencontainers.image.vendor" = "Freedpom";
            "org.opencontainers.image.licenses" = "MIT";
          };
        };
      };
    };
}
