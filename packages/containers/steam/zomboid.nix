{
  perSystem =
    {
      pkgs,
      inputs',
      base,
      lib,
      ...
    }:
    let
      n2c = inputs'.nix2container.packages.nix2container;
      steam = import ./steam-depot.nix { inherit pkgs lib; };

      zomboid-dedicated-server-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "zomboid-dedicated-server-unwrapped";
        version = "42.13.1";

        src = steam.steamFetch {
          name = "zomboid";
          appId = "380870";
          depotId = "380873";
          manifestId = "7247926727590960916";
          branch = "42.13.1";
          # Only download specific files
          fileList = [
            "ProjectZomboid64"
            "pzexe.jar"
            "regex:^(?!.*jre64).*\/java\/?$"
            "regex:^(?!.*jre64).*\\.so$"
          ];
          hash = "sha256-StO298c48LJI2axWTIyj3kWgh7/PcymO5QtTazu5W9U=";
        };

        installPhase = ''
          mkdir -p $out
          cp -r ./* $out/
          mkdir -p $out/lib
          mv **/*.so $out/lib
          rm -rf $out/natives $out/linux64
          chmod +x $out/ProjectZomboid64
        '';
      };

      zomboid-dedicated-server = pkgs.stdenvNoCC.mkDerivation {
        pname = "zomboid-dedicated-server";
        version = "42.13.1";

        src = zomboid-dedicated-server-unwrapped;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
        ];

        buildInputs = [
          pkgs.zlib
          pkgs.stdenv.cc.cc
          pkgs.libx11
          pkgs.libxext
          pkgs.libxi
          pkgs.libxrender
          pkgs.libxtst
          pkgs.libsm
          pkgs.libice
          pkgs.alsa-lib
        ];

        installPhase = ''
          mkdir -p $out
          cp -r ./* $out/
          cat > $out/ProjectZomboid64.json <<EOF
      {
        "mainClass": "zombie.network.GameServer",
        "classpath": [
          "java/.",
          "java/projectzomboid.jar"
        ],
        "vmArgs": [
          "-Djava.awt.headless=true",
          "-Xms6g",
          "-Xmx8g",
          "-Dzomboid.steam=1",
          "-Dzomboid.znetlog=1",
          "-Djava.library.path=linux64/:natives/",
          "-Djava.security.egd=file:/dev/urandom",
          "-XX:+UseZGC",
          "-XX:-OmitStackTraceInFastThrow",
          "-XX:-ZUncommit",
          "-XX:ParallelGCThreads=4",
          "-XX:ConcGCThreads=4",
          "-XX:-CreateCoredumpOnCrash"
        ]
      }
      EOF
      chmod 644 $out/ProjectZomboid64.json
        '';
      };
    in
    {
      packages = {
        inherit zomboid-dedicated-server;
        zomboid-oci = n2c.buildImage {
          name = "zomboid";
          meta = with pkgs.lib; {
            description = "Project Zomboid dedicated server (OCI image)";
            longDescription = ''
              Project Zomboid is the ultimate in zombie survival. Alone or in MP:
              you loot, build, craft, fight, farm and fish in a struggle to survive.

              This package provides Project Zomboid as an OCI-compatible container image,
              suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
            '';
            homepage = "https://projectzomboid.com/";
            changelog = "https://theindiestone.com/";
            #license = licenses.unfree; multi license
            platforms = platforms.linux;
          };

          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "zomboid-root" [
              pkgs.jre25_minimal
            ])
            (base.mkUser "pzuser" "101" "101" "/home/pzuser" "/bin/sh")
            (pkgs.runCommand "zomboid-scripts" { } ''
              mkdir -p $out/data
              mkdir -p $out/home/pzuser/Zomboid
              cp -r ${zomboid-dedicated-server}/* $out/data/
            '')
          ];

          perms = [
            {
              path = "/data";
              mode = "0755";
            }
            {
              path = "/home/pzuser";
              mode = "0755";
            }
          ];

          config = {
            user = "pzuser";
            workingDir = "/data";
            entrypoint = [ "/data/ProjectZomboid64" ];

            exposedPorts = {
              "16261/udp" = { };
              "16262/udp" = { };
            };

            healthcheck = {
              test = [
                "CMD-SHELL"
                "pgrep -f 'zombie.network.GameServer' > /dev/null || exit 1"
              ];
              interval = "30s";
              timeout = "10s";
              retries = 3;
              startPeriod = "60s";
            };

            labels = base.commonLabels // {
              "org.opencontainers.image.title" = "Project Zomboid";
              "org.opencontainers.image.description" = "Zombie survival dedicated server";
              #"org.opencontainers.image.licenses" = "Unfree";
            };
          };
        };
      };
    };
}
