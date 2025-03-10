{
  pkgs,
  lib,
  config,
  modulesPath,
  hostname,
  inputs,
  ...
}:
let
  cfg = config.ff.common;
in
{

  imports = [ (modulesPath + "/profiles/minimal.nix") ];

  disabledModules = [
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/base.nix")
  ];

  options.ff.common = {
    enable = lib.mkEnableOption "Enable nix system configuration";
  };

  config = lib.mkIf cfg.enable {
    # services.gpm.enable = true;
    networking = {
      hostName = hostname; # Define your hostname.
      hostId = "00000000"; # Define your host ID.
      networkmanager.enable = true;
    };
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "America/New_York";

    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
      packages = with pkgs; [ terminus_font ];
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "bk";
      extraSpecialArgs = {
        inherit inputs;
      };
    };
  };
}
