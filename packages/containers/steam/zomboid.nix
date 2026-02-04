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

      zomboid-dedicated-server = pkgs.stdenv.mkDerivation {
        pname = "zomboid-dedicated-server";
        version = "42.13.1";
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
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          #license = licenses.unfree; mf wont let me build
          platforms = platforms.linux;
        };


        srcs = [
          (steam.steamFetch { # Server Executable
            name = "zomboid-lib";
            appId = "380870";
            depotId = "380873";
            manifestId = "7247926727590960916";
            branch = "unstable";
            fileList = [
              "regex:^(?!.*jre64).*\\.so$"
            ];
            hash = "sha256-PmdYlvfOQCQw2dwFjz1HthYdE2WB3sooirBnMlNNc/E=";
          })
          (steam.steamFetch { # /media /java
            name = "zomboid-data";
            appId = "380870";
            depotId = "380871";
            manifestId = "8354051993030978772";
            branch = "42.13.1";
            hash = "sha256-HNdId6Zmo1FTRvj8cbOgiGiWf8iW+RurMaFm2WB8b2k=";
          })
        ];

        sourceRoot = ".";

        postUnpack = ''
          cp -r ./zomboid-lib-depot/. ./zomboid-data-depot/. .
          rm -rf ./zomboid-data-depot/ ./zomboid-lib-depot/
        '';

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
        ];

        buildInputs = [
          #pkgs.zlib
          pkgs.stdenv.cc.cc
          pkgs.libx11
          pkgs.libxext
          #pkgs.libxi
          #pkgs.libxrender
          #pkgs.libxtst
          pkgs.libsm
          pkgs.libice
          #pkgs.alsa-lib
        ];

        installPhase = ''
          mkdir -p $out $out/lib
          cp -r ./* $out/
          mv $out/**/*.so $out/lib/
          rm -rf $out/natives $out/linux64
        '';
      };
    in
    {
      packages = {
        inherit zomboid-dedicated-server;
        zomboid-oci = n2c.buildImage {
          name = "zomboid";
          copyToRoot = [
            base.runtimeEnv
            base.systemEnv
            (base.mkAppEnv "zomboid-root" [
              pkgs.zulu25
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
            entrypoint = [''java \
              -Djava.awt.headless=true \
              -Xms6g \
              -Xmx8g \
              -Dzomboid.steam=1 \
              -Dzomboid.znetlog=1 \
              -Djava.library.path="./lib" \
              -Djava.security.egd=file:/dev/urandom \
              -XX:+UseZGC \
              -XX:-OmitStackTraceInFastThrow \
              -XX:-ZUncommit \
              -XX:ParallelGCThreads=4 \
              -XX:ConcGCThreads=4 \
              -XX:-CreateCoredumpOnCrash \
              --enable-native-access=ALL-UNNAMED \
              -cp "java/.:java/projectzomboid.jar" \
              zombie.network.GameServer
              '' ];

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
              "org.opencontainers.image.licenses" = "Unfree";
            };
          };
        };
      };
    };
}
