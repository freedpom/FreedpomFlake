{ config, lib, ...}:
let
  cfg = config.ff.programs.alvr;
in 
{
  options.ff.programs.alvr.enable = lib.mkEnableOption "Enable ALVR";
  config = lib.mkIf cfg.enable {
    programs.alvr = {
      emable = true;
      openFirewall = true;
    };
  };
}
