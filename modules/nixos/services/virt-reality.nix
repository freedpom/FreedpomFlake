{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ff.services.virt-reality;
in
{
  # Configuration options for Ananicy service
  options.ff.services.virt-reality = {
    enable = lib.mkEnableOption "Enable the virtual reality";
    wivrnPkg = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wivrn;
      description = ''
        Wivrn package to use
      '';
    };
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Auto start
      '';
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        firewall
      '';
    };
    bitrate = lib.mkOption {
      type = lib.types.int;
      default = 50000000;
      description = ''
        The Bitrate
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      wivrn = {
        enable = true;
        package = lib.mkDefault cfg.wivrnPkg;
        defaultRuntime = true;

        inherit (cfg) autoStart;
        inherit (cfg) openFirewall;

        #extraPackages = [
        #  pkgs.opencomposite
        #];

        config = {
          enable = true;
          json = {
            scale = 1.0;
            inherit (cfg) bitrate;
            encoders = [
              {
                encoder = "vaapi";
                codec = "h265";
                width = 0.5;
                height = 1.0;
                offset_x = 0.0;
                offset_y = 0.0;
              }
              {
                encoder = "vaapi";
                codec = "h265";
                width = 0.5;
                height = 1.0;
                offset_x = 0.5;
                offset_y = 0.0;
              }
            ];
            application = [ pkgs.wlx-overlay-s ];
          };
        };
      };
    };
  };
}
