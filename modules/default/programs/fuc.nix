{
  flake.nixosModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.programs.fuc;
    in
    {
      options.freedpom.programs.fuc.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Fast Unix Commands - modern CLI utilities with improved performance and usability";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          fuc
        ];
      };
    };
}
