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
      inherit ((pkgs.callPackage ./fetch-steam.nix { inherit pkgs lib; })) fetchSteamDepot;

      zomboidLib = fetchSteamDepot {
        name = "zomboid-lib";
        appId = "380870";
        depotId = "380873";
        manifestId = "7247926727590960916";
        branch = "unstable";
        fileList = [
          "ProjectZomboid64"
          "regex:^(?!.*jre64).*\\.so$"
          "regex:^(?!.*jre64).*\\.jar$"
        ];
        hash = lib.fakeHash;
      };

      zomboidData = fetchSteamDepot {
        # /media /java
        name = "zomboid-data";
        appId = "380870";
        depotId = "380871";
        manifestId = "8354051993030978772";
        branch = "42.13.1";
        hash = "sha256-HNdId6Zmo1FTRvj8cbOgiGiWf8iW+RurMaFm2WB8b2k=";
      };

      steamSdk = pkgs.stdenv.mkDerivation rec {
        name = "steamworks-sdk-redist";
        version = "18639946";
        src = fetchSteamDepot {
          inherit name;
          appId = "1007";
          depotId = "1006";
          manifestId = "5587033981095108078"; # 23 July 2025 – 18:30:43 UTC
          hash = "sha256-CjrVpq5ztL6wTWIa63a/4xHM35DzgDR/O6qVf1YV5xw=";
        };

        dontBuild = true;
        dontConfigure = true;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
        ];

        buildInputs = [
          pkgs.stdenv.cc
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib
          cp linux64/steamclient.so $out/lib
          runHook postInstall
        '';

        meta = with lib; {
          description = "Steamworks SDK shared library";
          homepage = "https://steamdb.info/app/1007/";
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          license = licenses.unfreeRedistributable;
          platforms = [
            "i686-linux"
            "x86_64-linux"
          ];
        };
      };

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
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          license = licenses.unfreeRedistributable;
          platforms = platforms.linux;
        };

        src = zomboidData;

        #sourceRoot = ".";

        # postUnpack = ''
        #   mkdir -p ./lib/
        #   cp -r ./zomboid-lib-depot/. ./zomboid-data-depot/. .
        #   cp -r ./linux64/. ./natives/.
        #   rm -rf ./zomboid-data-depot/ ./zomboid-lib-depot/ ./linux64/ ./natives/
        # '';

        dontBuild = true;
        dontConfigure = true;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];

        buildInputs = [
          pkgs.stdenv.cc.cc
          pkgs.libx11
          pkgs.libxext
          pkgs.libsm
          pkgs.libice
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r ./* $out/
          #ln -sf ${steamSdk}/lib/steamclient.so $out/lib/steamclient.so
          #wrapProgram $out/ProjectZomboid64 \
          #  --prefix LD_LIBRARY_PATH : $out/lib:$\{zomboidLib}/linux64/:$\{zomboidLib}/natives/:$\{pkgs.zulu25}/lib \
          #  --prefix LD_PRELOAD : $\{pkgs.zulu25}/lib/server/libjsig.so
          runHook postInstall
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
              mkdir -p $out/data $out/home/pzuser/Zomboid/{Logs,Server,Saves,db}
              cp -r ${zomboid-dedicated-server}/* $out/data/
            '')
          ];

          maxLayers = 3;

          config = {
            user = "pzuser";
            workingDir = "/data";
            entrypoint = [
              "${pkgs.zulu25}/bin/java"
              "-Djava.awt.headless=true"
              "-Xms6g"
              "-Xmx8g"
              "-Dzomboid.steam=1"
              "-Dzomboid.znetlog=1"
              "-Djava.library.path=${zomboidLib}/linux64/:${zomboidLib}/natives/"
              "-Djava.security.egd=file:/dev/urandom"
              "-XX:+UseZGC"
              "-XX:-OmitStackTraceInFastThrow"
              "-XX:-ZUncommit"
              "-XX:ParallelGCThreads=4"
              "-XX:ConcGCThreads=4"
              "-XX:-CreateCoredumpOnCrash"
              "--enable-native-access=ALL-UNNAMED"
              "-cp"
              "java/.:java/projectzomboid.jar"
              "zombie.network.GameServer"
            ];

            volumes = {
              "/data" = { };
              "/home/pzuser/Zomboid" = { };
            };

            #env = ["LD_LIBRARY_PATH=./lib"];

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
