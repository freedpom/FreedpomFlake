{
  flake.nixosModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.services.ollama;
    in
    {
      # Configuration options for Ollama service
      options.freedpom.services.ollama = {
        enable = lib.mkEnableOption "Enable Ollama service for running large language models locally";
      };

      config = lib.mkIf cfg.enable {
        services = {
          ollama = {
            enable = true;
            package = pkgs.ollama-rocm;
          };
          open-webui = {
            enable = true;
          };
        };
      };
    };
}
