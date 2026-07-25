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
        };
      };
    };
}
