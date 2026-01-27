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

      authentikRoot = pkgs.buildEnv {
        name = "authentik-root";
        paths = [
          pkgs.authentik
          pkgs.python3
          pkgs.openssl
          pkgs.glibc
        ];
        pathsToLink = [
          "/bin"
        ];
      };

      common = {
        env = [
          "AUTHENTIK_POSTGRESQL__HOST=postgresql"
          "AUTHENTIK_POSTGRESQL__NAME=authentik"
          "AUTHENTIK_POSTGRESQL__USER=authentik"
          "AUTHENTIK_DISABLE_UPDATE_CHECK=true"
        ];

        volumes = {
          "/data" = { };
          "/templates" = { };
        };
      };
    in
    {
      packages = {
        authentik-server-oci = n2c.buildImage {
          name = "authentik-server-oci";
          meta = with pkgs.lib; {
            description = "Open-source identity provider (OCI image)";
            longDescription = ''
              Authentik is an open-source Identity Provider focused on flexibility
              and extensibility. It supports various protocols including OAuth2,
              OpenID Connect, SAML, and LDAP, making it suitable for single sign-on
              (SSO) scenarios.

              This package provides Authentik as an OCI-compatible container image,
              suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
            '';
            homepage = "https://goauthentik.io/";
            changelog = "https://github.com/goauthentik/authentik/releases";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            authentikRoot
          ];

          config = common // {
            entrypoint = [ "${pkgs.authentik}/bin/authentik" ];
            cmd = [ "server" ];

            user = "authentik";
            workingDir = "/";

            exposedPorts = {
              "9000/tcp" = { };
              "9443/tcp" = { };
            };

            stopSignal = "SIGTERM";

            labels = {
              "org.opencontainers.image.title" = "Authentik Server";
              "org.opencontainers.image.description" = "Open-source identity provider server";
              "org.opencontainers.image.vendor" = "Freedpom";
              "org.opencontainers.image.licenses" = "GPL-3.0-or-later";
            };
          };
        };

        authentik-worker-oci = n2c.buildImage {
          name = "authentik-worker-oci";
          meta = with pkgs.lib; {
            description = "Open-source identity provider worker (OCI image)";
            longDescription = ''
              Authentik is an open-source Identity Provider focused on flexibility
              and extensibility. It supports various protocols including OAuth2,
              OpenID Connect, SAML, and LDAP, making it suitable for single sign-on
              (SSO) scenarios.

              This package provides the Authentik worker as an OCI-compatible container image,
              suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
            '';
            homepage = "https://goauthentik.io/";
            changelog = "https://github.com/goauthentik/authentik/releases";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            authentikRoot
          ];

          config = common // {
            user = "authentik";
            workingDir = "/";

            entrypoint = [ "${pkgs.authentik}/bin/authentik" ];
            cmd = [ "worker" ];

            volumes = common.volumes // {
              "/var/run/docker.sock" = { };
              "/certs" = { };
            };

            stopSignal = "SIGTERM";

            labels = {
              "org.opencontainers.image.title" = "Authentik Worker";
              "org.opencontainers.image.description" = "Open-source identity provider worker";
              "org.opencontainers.image.vendor" = "Freedpom";
              "org.opencontainers.image.licenses" = "GPL-3.0-or-later";
            };
          };
        };
      };
    };
}
