{
  perSystem =
    { pkgs, ... }:
    {
      _module.args.base = {
        runtimeEnv = pkgs.buildEnv {
          name = "runtime-env";
          paths = [
            pkgs.bashInteractive
            pkgs.fakeNss
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.shadow
            pkgs.shadow.su
            pkgs.util-linux
            pkgs.glibc
          ];
          pathsToLink = [
            "/bin"
            "/sbin"
            "/etc"
            "/var"
          ];
        };

        systemEnv = pkgs.buildEnv {
          name = "system-env";
          paths = [
            pkgs.cacert
            pkgs.tzdata
            (pkgs.runCommand "nsswitch" { } ''
              mkdir -p $out/etc
              echo "passwd: files" > $out/etc/nsswitch.conf
              echo "group: files" >> $out/etc/nsswitch.conf
            '')
          ];
          pathsToLink = [
            "/etc"
            "/share"
          ];
        };

        # Common image configuration patterns
        commonLabels = {
          "org.opencontainers.image.vendor" = "Freedpom";
          "org.opencontainers.image.source" = "https://github.com/freedpom/FreedpomFlake";
        };

        mkUser =
          name: uid: gid: home: shell:
          pkgs.runCommand "${name}-user" { } ''
            set -eux
            mkdir -p $out/etc $out${home}
            groupadd --root $out -r -g ${toString gid} ${name}
            useradd --root $out -r -u ${toString uid} -g ${name} -d ${home} -s ${shell} ${name}
            chown -R ${name}:${name} $out${home}
          '';

        # Helper function to create buildEnv for applications
        mkAppEnv =
          name: paths:
          pkgs.buildEnv {
            inherit name;
            inherit paths;
            pathsToLink = [ "/bin" ];
          };

        # Helper function for common copyToRoot pattern
        mkCopyToRoot = extraPaths: [
          pkgs.buildEnv
          {
            name = "root";
            paths = extraPaths;
            pathsToLink = [
              "/bin"
              "/sbin"
            ];
          }
        ];
      };
    };
}
