{
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.persistence;
in
{
  options.ff.system.persistence = {
    enable = lib.mkEnableOption "Enable system persistence";
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."${config.hostConf.persistMain}" = {
      enable = true;

    };

  };
}
