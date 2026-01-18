{
  flake.nixosModules.default =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.system.fonts;
    in
    {
      options.freedpom.system.fonts = {
        enable = lib.mkEnableOption "System-wide font installation including Noto fonts, Liberation, and complete Nerd Fonts collection";
      };

      config = lib.mkIf cfg.enable {
        fonts.packages =
          with pkgs;
          [
            noto-fonts
            liberation_ttf
          ]
          ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
      };
    };
}
