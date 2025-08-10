{
  config,
  lib,
  ...
}: let
  cfg = config.ff.services.ollama;
in {
  # Configuration options for Ollama service
  options.ff.services.ollama = {
    enable = lib.mkEnableOption "Enable the Ollama service for running large language models locally";
  };

  config = lib.mkIf cfg.enable {
    services = {
      ollama = {
        enable = true;
        acceleration = "rocm";
      };
      open-webui = {
        enable = true;
      };
    };
  };
}
