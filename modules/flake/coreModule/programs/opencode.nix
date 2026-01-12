{
  flake.homeModules.core =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.ff.core.programs.opencode;
    in
    {
      options.ff.core.programs.opencode = {
        enable = lib.mkEnableOption "Enable opencode";
      };

      config = lib.mkIf cfg.enable {
        programs.opencode.enable = true;
      };
    };
}
