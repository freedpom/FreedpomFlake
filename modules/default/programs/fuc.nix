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
        description = "Enable Fast Unix Commands";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          fuc
        ];
      };
    };
}