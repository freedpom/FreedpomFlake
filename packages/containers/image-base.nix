{
  perSystem =
    { pkgs, ... }:
    {
      _module.args.base = {
        runtimeEnv = pkgs.buildEnv {
          name = "runtime-env";
          paths = [
            pkgs.bashInteractive
            pkgs.dash
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

        # Helper function to create user setup
        mkUser =
          name: uid: gid: home: shell:
          pkgs.runCommand "${name}-user-setup" { } ''
            mkdir -p $out/etc
            echo "${name}:x:${uid}:${gid}:${name} User:${home}:${shell}" >> $out/etc/passwd
            echo "${name}:x:${gid}:" >> $out/etc/group
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
