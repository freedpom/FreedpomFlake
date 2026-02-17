{
  perSystem =
    {
      pkgs,
      inputs',
      base,
      config,
      ...
    }:
    let
      n2c = inputs'.nix2container.packages.nix2container;
    in
    {
      packages.zomboid-oci = n2c.buildImage {
        name = "zomboid";
        meta = with pkgs.lib; {
          description = "Project Zomboid dedicated server (OCI image)";
          longDescription = ''
            Project Zomboid is the ultimate in zombie survival. Alone or in MP:
            you loot, build, craft, fight, farm and fish in a struggle to survive.
            This is the dedicated server packaged as an OCI-compatible container image.
          '';
          homepage = "https://projectzomboid.com/";
          changelog = "https://theindiestone.com/";
          license = pkgs.lib.licenses.unfreeRedistributable;
          platforms = pkgs.lib.platforms.linux;
          sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "zomboid-root" [
            config.packages.zomboid-dedicated-server
            pkgs.zulu25
            pkgs.curl
          ])
          (base.mkUsersWithRoot "zomboid" 1000 1000 "/var/zomboid" "/bin/bash")
          (pkgs.runCommand "zomboid-setup" { } ''
            mkdir -p $out/var/zomboid
            mkdir -p $out/var/zomboid/config
            mkdir -p $out/var/zomboid/cache
            chmod 755 $out/var/zomboid
          '')
        ];

        config = {
          user = "zomboid";
          workingDir = "/var/zomboid";

          env = [
            "PZ_CACHEDIR=/var/zomboid/cache"
            "PZ_MEM=4g"
            "PZ_STEAM=1"
            "PZ_SERVERNAME=servertest"
            "PZ_ADMINUSER=admin"
            "PZ_ADMINPASS=password"
            "PZ_GAME_OPTS="
            "HOME=/var/zomboid"
          ];

          entrypoint = [ "${pkgs.bash}/bin/bash" ];

          cmd = [
            "-c"
            ''
              echo "Starting Project Zomboid Dedicated Server..."
              echo "Server Name: $PZ_SERVERNAME"
              echo "Memory: $PZ_MEM"

              mkdir -p $PZ_CACHEDIR/Zomboid

              exec ${config.packages.zomboid-dedicated-server}/bin/ProjectZomboid
            ''
          ];

          exposedPorts = {
            "16261/udp" = { }; # Steam query
            "16262/udp" = { }; # Game port
            "8766/udp" = { }; # Steam master server
            "8767/udp" = { }; # Steam communication
          };

          volumes = {
            "/var/zomboid" = { };
          };

          stopSignal = "SIGTERM";

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "Project Zomboid";
            "org.opencontainers.image.description" = "Project Zomboid dedicated server";
            "org.opencontainers.image.licenses" = "Proprietary";
          };
        };
      };
    };
}
