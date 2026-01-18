{
  flake.homeModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.programs.opencode;
    in
    {
      options.freedpom.programs.opencode = {
        enable = lib.mkEnableOption "opencode AI coding assistant";
      };

      config = lib.mkIf cfg.enable {
        programs.opencode.enable = true;
      };
    };
}
