{
  flake.nixosModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.programs.uutils;
    in
    {
      options.freedpom.programs.uutils.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable uutils rust replacement of gnu coreutils";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          uutils-coreutils
        ];
      };
    };
}
