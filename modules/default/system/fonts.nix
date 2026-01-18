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
        enable = lib.mkEnableOption "Enable fonts (requires nixpkgs-unstable)";
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
