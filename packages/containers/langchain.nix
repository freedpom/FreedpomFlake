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
      packages.langchain-oci = n2c.buildImage {
        name = "langchain";
        meta = with pkgs.lib; {
          description = "LangChain-based AI application framework (OCI image)";
          longDescription = ''
            LangChain is a framework for developing applications powered by language models.
            It enables applications that are data-aware and agentic, allowing LLMs to connect
            with external data sources and APIs.

            This package provides a LangChain development environment as an OCI-compatible
            container image, suitable for use with Docker, Podman, Kubernetes, and other
            OCI runtimes. It includes Python, LangChain, and related packages.
          '';
          homepage = "https://www.langchain.com/";
          license = pkgs.lib.licenses.mit;
          platforms = pkgs.lib.platforms.linux;
        };

        copyToRoot = [
          base.runtimeEnv
          base.systemEnv
          (base.mkAppEnv "langchain-root" [
            (pkgs.python3.withPackages (
              ps: with ps; [
                langchain
                langchain-community
                langchain-core
                langchain-openai
                openai
                requests
                fastapi
                uvicorn
                pydantic
              ]
            ))
            pkgs.curl
          ])
          (base.mkUser "langchain" "1000" "1000" "/app" "/bin/sh")
          (pkgs.runCommand "langchain-dirs" { } ''
            mkdir -p $out/app
            mkdir -p $out/data
          '')
        ];

        perms = [
          {
            path = "/app";
            regex = ".*";
            mode = "0755";
          }
          {
            path = "/data";
            regex = ".*";
            mode = "0755";
          }
        ];

        config = {
          user = "langchain";
          workingDir = "/app";

          env = [
            "PYTHONUNBUFFERED=1"
            "PYTHONDONTWRITEBYTECODE=1"
            "LANGCHAIN_VERBOSE=false"
            "LANGCHAIN_PROJECT=default"
            "APP_PORT=8000"
          ];

          entrypoint = [ "${pkgs.bash}/bin/bash" ];

          cmd = [
            "-c"
            ''
              echo "LangChain environment ready!"
              echo "Available packages:"
              python3 -c "import langchain; print(f'LangChain version: {langchain.__version__}')"
              echo ""
              echo "Example usage:"
              echo "  python3 your_langchain_app.py"
              echo ""
              echo "Or start a development server:"
              echo "  uvicorn main:app --host 0.0.0.0 --port 8000"
              echo ""
              echo "Keep container running..."
              tail -f /dev/null
            ''
          ];

          exposedPorts = {
            "8000/tcp" = { };
          };

          volumes = {
            "/app" = { };
            "/data" = { };
          };

          labels = base.commonLabels // {
            "org.opencontainers.image.title" = "LangChain";
            "org.opencontainers.image.description" = "LangChain-based AI application framework";
            "org.opencontainers.image.licenses" = "MIT";
          };
        };
      };
    };
}
