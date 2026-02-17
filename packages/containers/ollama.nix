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
          base.rootUser
          (pkgs.runCommand "ollama-setup" { } ''
            mkdir -p $out/root/.ollama
          '')
        ];

        config = {
          user = "root";
          workingDir = "/root";

          env = [
            "OLLAMA_HOST=0.0.0.0:11434"
            "OLLAMA_MODELS=/root/.ollama/models"
            "OLLAMA_KEEP_ALIVE=5m"
          ];

          entrypoint = [ "${pkgs.ollama}/bin/ollama" ];
          cmd = [ "serve" ];

          exposedPorts = {
            "11434/tcp" = { };
          };

          volumes = {
            "/root/.ollama" = { };
          };

          healthcheck = {
            test = [
              "CMD-SHELL"
              "${pkgs.curl}/bin/curl -f http://localhost:11434/api/tags || exit 1"
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
