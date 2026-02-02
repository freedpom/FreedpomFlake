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
          name = "authentik-server";
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
            (base.mkAppEnv "authentik-root" [
              pkgs.authentik
              pkgs.python3
              pkgs.openssl
              pkgs.glibc
              pkgs.curl
            ])
            (base.mkUser "authentik" "104" "104" "/" "/bin/sh")
          ];

          perms = [
            {
              path = "/data";
              regex = ".*";
              mode = "0755";
            }
            {
              path = "/templates";
              regex = ".*";
              mode = "0755";
            }
          ];

          config = common // {
            user = "authentik";
            workingDir = "/";

            entrypoint = [ "${pkgs.authentik}/bin/ak" ];
            cmd = [ "server" ];

            exposedPorts = {
              "9000/tcp" = { };
              "9443/tcp" = { };
            };

            healthcheck = {
              test = [
                "CMD-SHELL"
                "${pkgs.curl}/bin/curl -f http://localhost:9000/-/health/ || exit 1"
              ];
              interval = "30s";
              timeout = "10s";
              retries = 3;
              startPeriod = "30s";
            };

            labels = base.commonLabels // {
              "org.opencontainers.image.title" = "Authentik Server";
              "org.opencontainers.image.description" = "Open-source identity provider server";
              "org.opencontainers.image.licenses" = "GPL-3.0-or-later";
            };
          };
        };

        authentik-worker-oci = n2c.buildImage {
          name = "authentik-worker";
          meta = with pkgs.lib; {
            description = "Open-source identity provider worker (OCI image)";
            longDescription = ''
              Authentik is an open-source Identity Provider focused on flexibility
              and extensibility. It supports various protocols including OAuth2,
              OpenID Connect, SAML, and LDAP, making it suitable for single sign-on
              (SSO) scenarios.

              This package provides Authentik worker as an OCI-compatible container image,
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
            (base.mkAppEnv "authentik-root" [
              pkgs.authentik
              pkgs.python3
              pkgs.openssl
              pkgs.glibc
              pkgs.curl
            ])
            (base.mkUser "authentik" "104" "104" "/" "/bin/sh")
          ];

          perms = [
            {
              path = "/data";
              regex = ".*";
              mode = "0755";
            }
            {
              path = "/templates";
              regex = ".*";
              mode = "0755";
            }
            {
              path = "/certs";
              regex = ".*";
              mode = "0755";
            }
          ];

          config = common // {
            user = "authentik";
            workingDir = "/";

            entrypoint = [ "${pkgs.authentik}/bin/ak" ];
            cmd = [ "worker" ];

            volumes = common.volumes // {
              "/var/run/docker.sock" = { };
              "/certs" = { };
            };

            healthcheck = {
              test = [
                "CMD-SHELL"
                "pgrep -f 'authentik worker' || exit 1"
              ];
              interval = "30s";
              timeout = "10s";
              retries = 3;
              startPeriod = "10s";
            };

            labels = base.commonLabels // {
              "org.opencontainers.image.title" = "Authentik Worker";
              "org.opencontainers.image.description" = "Open-source identity provider worker";
              "org.opencontainers.image.licenses" = "GPL-3.0-or-later";
            };
          };
        };
      };
    };
}
