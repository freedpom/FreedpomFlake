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

      qdrantBinary = pkgs.stdenv.mkDerivation rec {
        pname = "qdrant";
        version = "1.13.4";
        src = pkgs.fetchurl {
          url = "https://github.com/qdrant/qdrant/releases/download/v${version}/qdrant-x86_64-unknown-linux-gnu.tar.gz";
          hash = "sha256-UgZlYkmZM5pgD4wPeGlYK0QIlS1PAxc7TGXSQiyF5K4=";
        };
        sourceRoot = ".";
        nativeBuildInputs = with pkgs; [ autoPatchelfHook ];
        buildInputs = with pkgs; [
          glibc
          openssl
          stdenv.cc.cc.lib
          gcc
        ];
        installPhase = ''
          mkdir -p $out/bin
          cp qdrant $out/bin/
          chmod +x $out/bin/qdrant
        '';
        meta = with lib; {
          description = "Vector database and vector similarity search engine";
          homepage = "https://qdrant.tech/";
          license = licenses.asl20;
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      packages.qdrant-oci = n2c.buildImage {
        name = "qdrant";
        meta = with pkgs.lib; {
          description = "Vector database and vector similarity search engine (OCI image)";
          longDescription = ''
            Qdrant is a vector database and vector similarity search engine. It provides
            a production-ready service with a convenient API to store, search, and manage
            vectors with additional payload. Qdrant is tailored to extended filtering support.

            This package provides Qdrant as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://qdrant.tech/";
          changelog = "https://github.com/qdrant/qdrant/releases";
          license = licenses.asl20;
          platforms = platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "qdrant-root" [ qdrantBinary ])
          (base.mkUsersWithRoot "qdrant" "1000" "1000" "/qdrant" "/bin/sh")
          (pkgs.runCommand "qdrant-setup" { } ''
                        mkdir -p $out/qdrant/storage
                        mkdir -p $out/qdrant/snapshots
                        # Create entrypoint script
                        mkdir -p $out/usr/local/bin
                        cat > $out/usr/local/bin/start-qdrant << 'EOF'
            #!/bin/sh
            chown -R qdrant:qdrant /qdrant
            exec su -s /bin/sh qdrant -c 'QDRANT__STORAGE__STORAGE_PATH=/qdrant/storage QDRANT__SNAPSHOTS__SNAPSHOTS_PATH=/qdrant/snapshots QDRANT__SERVICE__HTTP_PORT=6333 QDRANT__SERVICE__GRPC_PORT=6334 exec ${qdrantBinary}/bin/qdrant'
            EOF
                        chmod +x $out/usr/local/bin/start-qdrant
          '')
        ];

        config = {
          user = "root";
          workingDir = "/qdrant";
          entrypoint = [ "/usr/local/bin/start-qdrant" ];
          exposedPorts = {
            "6333/tcp" = { };
            "6334/tcp" = { };
          };
          volumes = {
            "/qdrant/storage" = { };
            "/qdrant/snapshots" = { };
          };
          healthcheck = {
            test = [
              "CMD-SHELL"
              "curl -f http://localhost:6333/readyz || exit 1"
            ];
            interval = "30s";
            timeout = "10s";
            retries = 3;
            startPeriod = "30s";
          };
          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "Qdrant";
            "org.opencontainers.image.description" = "Vector database and vector similarity search engine";
            "org.opencontainers.image.licenses" = "Apache-2.0";
          };
        };
      };
    };
}
