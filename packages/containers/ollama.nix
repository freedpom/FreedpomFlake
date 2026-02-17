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
    in
    {
      packages.ollama-oci = n2c.buildImage {
        name = "ollama";
        meta = with pkgs.lib; {
          description = "Run LLMs locally with ease (OCI image)";
          longDescription = ''
            Ollama is a tool for running large language models locally. It provides a simple
            API for running and managing models, with support for various models like Llama 2,
            Mistral, and Code Llama.

            This package provides Ollama as an OCI-compatible container image,
            suitable for use with Docker, Podman, Kubernetes, and other OCI runtimes.
          '';
          homepage = "https://ollama.com/";
          changelog = "https://github.com/ollama/ollama/releases";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "ollama-root" [ pkgs.ollama ])
          (base.mkUsersWithRoot "ollama" "1000" "1000" "/home/ollama" "/bin/sh")
          (pkgs.runCommand "ollama-setup" { } ''
                        mkdir -p $out/home/ollama/.ollama
                        # Create entrypoint script
                        mkdir -p $out/usr/local/bin
                        cat > $out/usr/local/bin/start-ollama << 'EOF'
            #!/bin/sh
            chown -R ollama:ollama /home/ollama
            exec su -s /bin/sh ollama -c 'OLLAMA_HOST=0.0.0.0:11434 OLLAMA_MODELS=/home/ollama/.ollama/models OLLAMA_KEEP_ALIVE=5m exec ${pkgs.ollama}/bin/ollama serve'
            EOF
                        chmod +x $out/usr/local/bin/start-ollama
          '')
        ];

        config = {
          user = "root";
          workingDir = "/home/ollama";
          entrypoint = [ "/usr/local/bin/start-ollama" ];
          exposedPorts = {
            "11434/tcp" = { };
          };
          volumes = {
            "/home/ollama/.ollama" = { };
          };
          healthcheck = {
            test = [
              "CMD-SHELL"
              "curl -f http://localhost:11434/api/tags || exit 1"
            ];
            interval = "30s";
            timeout = "10s";
            retries = 3;
            startPeriod = "60s";
          };
          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "Ollama";
            "org.opencontainers.image.description" = "Run LLMs locally with ease";
            "org.opencontainers.image.licenses" = "MIT";
          };
        };
      };
    };
}
