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

        consoleFont = lib.mkOption {
          type = lib.types.str;
          default = "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
          description = "Console font to use for early boot and virtual terminals";
        };

        consoleFontPackage = lib.mkOption {
          type = lib.types.package;
          default = pkgs.terminus_font;
          description = "Package containing the console font";
        };
      };

      config = lib.mkIf cfg.enable {
        fonts.packages =
          with pkgs;
          [
            noto-fonts
            liberation_ttf
          ]
          ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

        # Console font configuration
        console = {
          earlySetup = true;
          font = cfg.consoleFont;
          packages = [ cfg.consoleFontPackage ];
        };
      };
    };
}
