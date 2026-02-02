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

      zomboidServerFiles = pkgs.stdenv.mkDerivation {
        pname = "zomboid-server-files";
        version = "unstable-2025-02-01";

        nativeBuildInputs = [ pkgs.steamcmd pkgs.jdk25_headless ];

        unpackPhase = ''
          mkdir -p $out
        '';

        buildPhase = ''
          echo "Downloading Project Zomboid server files with steamcmd..."
          export HOME=$TMPDIR
          export STEAM_DISABLE_SANDBOX=1
          mkdir -p $HOME/.steam/sdk32 $HOME/.steam/sdk64
          ln -sf ${pkgs.steamcmd}/bin/steamcmd/linux32/steamclient.so $HOME/.steam/sdk32/steamclient.so || true
          ln -sf ${pkgs.steamcmd}/bin/steamcmd/linux64/steamclient.so $HOME/.steam/sdk64/steamclient.so || true
          steamcmd +force_install_dir $out +login anonymous +app_update 380870 validate +quit
        '';

        dontStrip = true;
        dontFixup = true;

        outputHash = "gfXg8QZGZEhN86xCvBqvid1px1gVCg0+UeUHzbVxHg4=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      };

      startupScript = pkgs.writeShellScript "start-zomboid.sh" ''
        set -e

        echo "=== Project Zomboid Dedicated Server Setup ==="
        export HOME=/home/pzuser

        SERVER_NAME=''${PZ_SERVER_NAME:-servertest}
        echo "Server name: $SERVER_NAME"

        echo "Copying server files to /data..."
        cp -r ${zomboidServerFiles}/* /data/
        chmod -R +w /data

        echo "Creating server configuration..."
        cat > "/data/''${SERVER_NAME}.ini" << EOF
        DefaultPort=16261
        DefaultDirectConnectPort=16262
        SteamPort1=8766
        SteamPort2=8767
        PublicServer=true
        PublicDesc=Project Zomboid Server
        ServerName=''${SERVER_NAME}
        Password=
        MaxPlayers=16
        EOF

        echo "Starting server..."
        cd /data
        chmod +x start-server.sh
        exec ./start-server.sh -servername ''${SERVER_NAME}
      '';
    in
    {
      packages.zomboid-oci = n2c.buildImage {
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
          license = licenses.unfree;
          platforms = platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "zomboid-root" [
            pkgs.jre25_headless
          ])
          (base.mkUser "pzuser" "101" "101" "/home/pzuser" "/bin/sh")
          (pkgs.runCommand "zomboid-scripts" { } ''
            mkdir -p $out/home/pzuser
            mkdir -p $out/data
            cp ${startupScript} $out/data/start-zomboid.sh
          '')
        ];

        perms = [
          {
            path = "/data";
            mode = "0777";
          }
          {
            path = "/data/start-zomboid.sh";
            mode = "0755";
          }
          {
            path = "/home/pzuser";
            mode = "0777";
          }
        ];

        config = {
          workingDir = "/data";

          env = [
            "PZ_SERVER_NAME=servertest"
            "PZ_MEMORY=4g"
            "STEAM_DISABLE_SANDBOX=1"
          ];

          entrypoint = [ "/data/start-zomboid.sh" ];

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
}
