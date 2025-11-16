localFlake:
{
  ...
}:
{
  imports = [
    localFlake.inputs.flake-root.flakeModule
    localFlake.inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        programs = {
          actionlint.enable = true;
          nixfmt.enable = true;
          deadnix.enable = true;
          mdformat.enable = true;
          shfmt.enable = true;
          statix.enable = true;
          typos = {
            enable = true;
            excludes = [ "*.png" ];
            configFile =
              let
                tomlConfig = '''';
                tomlFile = pkgs.writeText "typos.toml" tomlConfig;
              in
              toString tomlFile;
          };
        };
      };
    };
}
