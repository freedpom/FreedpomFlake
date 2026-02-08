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
      inherit ((pkgs.callPackage ../../fetchsteam/fetch-steam.nix { inherit pkgs lib; })) fetchSteamDepot;

      steamSdk = fetchSteamDepot {
        name = "steamworks-sdk-redist";
        appId = "1007";
        depotId = "1006";
        manifestId = "5587033981095108078"; # 23 July 2025 – 18:30:43 UTC
        nativeBuildInputs = [
          pkgs.autoPatchelfHook
        ];
        postFetch = ''
          mkdir -p $out/lib
          cp $out/linux64/steamclient.so $out/lib
          rm -rf $out/linux64/ $out/steamclient.so $out/libsteamwebrtc.so
        '';
        hash = "sha256-FPgE8duGCQWeh16ONcYlpw/932yp0zxpEEr2phHRzDg=";
        meta = with lib; {
          description = "Steamworks SDK shared library";
          homepage = "https://steamdb.info/app/1007/";
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          license = licenses.unfreeRedistributable;
          platforms = [
            "x86_64-linux"
          ];
        };
      };

      zomboidLib = fetchSteamDepot {
        name = "zomboid-lib";
        appId = "380870";
        depotId = "380873";
        manifestId = "7247926727590960916";
        branch = "unstable";
        fileList = [
          "regex:^(?!.*jre64).*\\.so$"
        ];
        postFetch = ''
          mkdir -p $out/lib/
          cp -r $out/linux64/. $out/natives/. $out/lib/
          cp $out/libpzexe_jni64.so $out/lib/libpzexe_jni64.so
          rm -rf $out/linux64/ $out/natives/ $out/libpzexe_jni64.so
        '';
        hash = "sha256-iA96Hn27vXjMT2F0V1aPTKHLYK0is2ni4bo31YRFeik=";
      };

      zomboidData = fetchSteamDepot {
        name = "zomboid-data";
        appId = "380870";
        depotId = "380871";
        manifestId = "8354051993030978772";
        branch = "42.13.1";
        fileList = [
          "regex:^(?:\\.\\/)?(media)\\/.*"
          "regex:^.*\\.(lua|lbc|jar)$"
          "steam_appid.txt"
        ];
        postFetch = ''
          mkdir -p $out/share/zomboid
          ln -sf ${steamSdk}/lib/steamclient.so $out/share/zomboid/steamclient.so
          find "$out" -mindepth 1 -maxdepth 1 ! -name share \
            -exec mv {} "$out/share/zomboid" \;
        '';
        hash = "sha256-dJEdjLIiZTsE2L03GU0GW8/MEssIe/Av4gOcmh4vfpg=";
      };

      zomboid-dedicated-server = pkgs.stdenv.mkDerivation {
        pname = "zomboid-dedicated-server";
        version = "42.13.1";
        meta = with pkgs.lib; {
          description = "Project Zomboid dedicated server";
          longDescription = ''
            Project Zomboid is the ultimate in zombie survival. Alone or in MP:
            you loot, build, craft, fight, farm and fish in a struggle to survive.
          '';
          homepage = "https://projectzomboid.com/";
          changelog = "https://theindiestone.com/";
          sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
          license = licenses.unfreeRedistributable;
          platforms = platforms.linux;
        };

        dontUnpack = true;
        dontBuild = true;
        dontConfigure = true;

        installPhase = ''
          mkdir -p $out/bin
          cat > $out/bin/ProjectZomboid <<'EOF'
        #!/usr/bin/env bash

        export LD_LIBRARY_PATH="${pkgs.curl.out}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${zomboidLib}/lib:${pkgs.zulu25}/lib:${steamSdk}/lib/steamclient.so:$LD_LIBRARY_PATH"
        export LD_PRELOAD="${pkgs.zulu25}/lib/server/libjsig.so"

        export PZ_CACHEDIR="''\${PZ_CACHEDIR:-$XDG_CACHE_HOME}"
        mkdir -p "''\$PZ_CACHEDIR/Zomboid"

        export PZ_XMS="''\${PZ_XMS:--Xms6g}"
        export PZ_XMX="''\${PZ_XMX:--Xmx8g}"

        export PZ_PARALLEL_GC_THREADS="''\${PZ_PARALLEL_GC_THREADS:-4}"
        export PZ_CONC_GC_THREADS="''\${PZ_CONC_GC_THREADS:-4}"

        if [ "''\${PZ_STEAM:-true}" = "true" ]; then
          export STEAM_ARG="-Dzomboid.steam=1"
        else
          export STEAM_ARG="-Dzomboid.steam=0"
        fi

        export PZ_SERVERNAME="''\${PZ_SERVERNAME:-BigBallz}"
        export PZ_ADMINUSER="''\${PZ_ADMINUSER:-admin}"
        export PZ_ADMINPASS="''\${PZ_ADMINPASS:-password}"
        export PZ_GAME_OPTS="''\${PZ_GAME_OPTS:-}"

        cd ${zomboidData}/share/zomboid
        ${pkgs.zulu25}/bin/java \
          -Djava.awt.headless=true \
          $PZ_XMS $PZ_XMX \
          $STEAM_ARG \
          -Ddeployment.user.cachedir="$PZ_CACHEDIR" \
          -Djava.library.path="${zomboidLib}/lib" \
          -Djava.security.egd=file:/dev/urandom \
          -XX:+UseZGC \
          -XX:-OmitStackTraceInFastThrow \
          -XX:-ZUncommit \
          -XX:ParallelGCThreads=$PZ_PARALLEL_GC_THREADS \
          -XX:ConcGCThreads=$PZ_CONC_GC_THREADS \
          -XX:-CreateCoredumpOnCrash \
          --enable-native-access=ALL-UNNAMED \
          -cp "${zomboidData}/share/zomboid/java/.:${zomboidData}/share/zomboid/java/projectzomboid.jar" \
          zombie.network.GameServer \
            -servername "$PZ_SERVERNAME" \
            -adminusername "$PZ_ADMINUSER" \
            -adminpassword "$PZ_ADMINPASS" \
            $PZ_GAME_OPTS
        EOF
          chmod +x $out/bin/ProjectZomboid
        '';

      };
    in
    {
      packages = {
        inherit zomboid-dedicated-server;
      };
    };
}
