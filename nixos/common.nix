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
    services.gpm.enable = true;

    fonts.packages =
      with pkgs;
      [
        noto-fonts
        liberation_ttf

      ]
      ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    networking = {
      hostName = hostname; # Define your hostname.
      hostId = "00000000"; # Define your host ID.
      networkmanager.enable = true;
    };
    i18n.defaultLocale = "en_US.UTF-8";

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    time.timeZone = "America/New_York";

    console = {
      earlySetup = true;
      #font = "Lat2-Terminus16";
      useXkbConfig = true;
    };

    boot.initrd.includeDefaultModules = false;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bk";
      extraSpecialArgs = {
        inherit inputs;
      };
    };
  };
}
