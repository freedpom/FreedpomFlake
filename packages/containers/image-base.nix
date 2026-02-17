{
  perSystem =
    { pkgs, ... }:
    {
      _module.args.base = {
        runtimeEnv = pkgs.buildEnv {
          name = "runtime-env";
          paths = [
            pkgs.bashInteractive
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
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
            # Create group file
            echo "${name}:x:${toString gid}:" > $out/etc/group
            # Create passwd file  
            echo "${name}:x:${toString uid}:${toString gid}:${name}:${home}:${shell}" > $out/etc/passwd
          '';

        # Create root user entry for containers that need to start as root
        rootUser = pkgs.runCommand "root-user" { } ''
          mkdir -p $out/etc
          echo "root:x:0:0:root:/root:/bin/sh" > $out/etc/passwd
          echo "root:x:0:" > $out/etc/group
        '';

        # Create both root and app user in a single file to avoid conflicts
        mkUsersWithRoot =
          name: uid: gid: home: shell:
          pkgs.runCommand "${name}-users" { } ''
            set -eux
            mkdir -p $out/etc $out${home}
            # Create group file with both root and app group
            echo "root:x:0:" > $out/etc/group
            echo "${name}:x:${toString gid}:" >> $out/etc/group
            # Create passwd file with both root and app user
            echo "root:x:0:0:root:/root:/bin/sh" > $out/etc/passwd
            echo "${name}:x:${toString uid}:${toString gid}:${name}:${home}:${shell}" >> $out/etc/passwd
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
