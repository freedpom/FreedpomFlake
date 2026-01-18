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
        description = "Cross-platform Rust implementation of GNU coreutils with consistent behavior and improved performance";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          uutils-coreutils
        ];
      };
    };
}
