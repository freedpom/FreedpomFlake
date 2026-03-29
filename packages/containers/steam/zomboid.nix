{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit ((pkgs.callPackage ../../fetchsteam/fetch-steam.nix { inherit pkgs lib; })) fetchSteamDepot;

      steamSdk = fetchSteamDepot {
        name = "steamworks-sdk-redist";
        appId = "1007";
        depotId = "1006";
        manifestId = "6403079453713498174"; # 8 December 2025 – 18:16:30 UTC
        nativeBuildInputs = [
          pkgs.autoPatchelfHook
        ];
        postFetch = ''
          mkdir -p $out/lib
          cp $out/linux64/steamclient.so $out/lib
          rm -rf $out/linux64/ $out/steamclient.so $out/libsteamwebrtc.so
        '';
        hash = "sha256-fyE5tA/m8daAOIy7ziDGlqFjuQRb++m7Dx7DsEX+bh0=";
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
        manifestId = "1926980309109431060"; # 11 March, 2026
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
        hash = "sha256-2/6AhKNnNOvGILixXQp25ob6OrKtACGqLo2EBIFAdj8=";
      };

      zomboidData = fetchSteamDepot {
        name = "zomboid-data";
        appId = "380870";
        depotId = "380871";
        manifestId = "5369213955995092828"; # 29 March, 2026
        branch = "unstable";
        fileList = [
          "regex:^(?:\\.\\/)?(media)\\/.*"
          "regex:^.*\\.(lua|lbc|jar)$"
          "steam_appid.txt"
        ];
        postFetch = ''
          mkdir -p $out/share/zomboid
          find "$out" -mindepth 1 -maxdepth 1 ! -name share \
            -exec mv {} "$out/share/zomboid" \;
        '';
        hash = "sha256-ARNUoldUuK7Ds+v6YbBfUUfgGjd13+t0v34D6XURCOM=";
      };

      zomboid-dedicated-server = pkgs.stdenv.mkDerivation {
        pname = "zomboid-dedicated-server";
        version = "42.15.2";
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
            cp ${steamSdk}/lib/steamclient.so $out/bin/
            cat > $out/bin/ProjectZomboid <<'EOF'
          #!/usr/bin/env bash

          export LD_LIBRARY_PATH="${pkgs.curl.out}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${zomboidLib}/lib:${steamSdk}/lib:${pkgs.zulu25}/lib:$LD_LIBRARY_PATH"
          export LD_PRELOAD="${pkgs.zulu25}/lib/server/libjsig.so"

          export PZ_CACHEDIR="''${PZ_CACHEDIR:-$XDG_CACHE_HOME}"
          mkdir -p "''${PZ_CACHEDIR}/Zomboid"
          export PZ_MEM="''${PZ_XMS:-10g}"
          export PZ_STEAM="''${PZ_STEAM:-1}"
          export PZ_SERVERNAME="''${PZ_SERVERNAME:-servertest}"
          export PZ_ADMINUSER="''${PZ_ADMINUSER:-admin}"
          export PZ_ADMINPASS="''${PZ_ADMINPASS:-password}"
          export PZ_GAME_OPTS="''${PZ_GAME_OPTS:-}"

          cd ${zomboidData}/share/zomboid

          ${pkgs.zulu25}/bin/java \
            -Djava.awt.headless=true \
            -Xms$PZ_MEM \
            -Xmx$PZ_MEM \
            -Dzomboid.steam=$PZ_STEAM \
            -Ddeployment.user.cachedir="$PZ_CACHEDIR" \
            -Djava.library.path="${zomboidLib}/lib" \
            -Djava.security.egd=file:/dev/urandom \
            -XX:+AlwaysPreTouch \
            -XX:+UseZGC \
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
