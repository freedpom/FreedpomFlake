{
  config,
  hostname,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  cfg = config.ff.common;
in
{
  # Import necessary modules
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  # Disable unnecessary modules
  disabledModules = [
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/base.nix")
  ];

  options.ff.common = {
    enable = lib.mkEnableOption "Enable nix system configuration";
  };

  config = lib.mkIf cfg.enable {
    # Console Settings
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-120n.psf.gz";
      packages = with pkgs; [ terminus_font ];
    };

    # Home Manager Settings
    home-manager = {
      backupFileExtension = "bk";
      extraSpecialArgs = {
        inherit inputs;
      };
      useGlobalPkgs = false;
      useUserPackages = true;
    };

    # System Settings
    i18n.defaultLocale = "en_US.UTF-8";

    networking = {
      hostId = "00000000"; # Define your host ID.
      hostName = hostname; # Define your hostname.
      networkmanager.enable = true;
    };

    time.timeZone = "America/New_York";
  };
}
