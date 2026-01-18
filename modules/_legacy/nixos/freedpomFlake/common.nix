{
  config,
  hostname,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  cfg = config.ff.common;
in
{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  disabledModules = [
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/base.nix")
  ];

  options.ff.common = {
    enable = lib.mkEnableOption "Enable nix system configuration";
  };

  config = lib.mkIf cfg.enable {
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
      packages = with pkgs; [ terminus_font ];
    };

    i18n.defaultLocale = "en_US.UTF-8";

    networking = {
      hostId = "00000000";
      hostName = hostname;
    };

    time.timeZone = "America/New_York";
  };
}
