{
  flake.nixosModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.programs.sudo-rs;
    in
    {
      options.freedpom.programs.sudo-rs = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable sudo-rs instead of regular sudo";
        };
      };

      config = lib.mkIf cfg.enable {
        security = {
          sudo.enable = lib.mkForce false;
          sudo-rs = {
            enable = true;
            execWheelOnly = true;
          };
        };
      };
    };
}