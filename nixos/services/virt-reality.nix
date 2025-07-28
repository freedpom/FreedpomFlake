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
  };

  config = lib.mkIf cfg.enable {
    services = {
      wivrn = {
        enable = true;
        defaultRuntime = true;

        inherit (cfg) autoStart;
        inherit (cfg) openFirewall;

        extraPackages = [
          pkgs.opencomposite
        ];

        config = {
          enable = true;
          json = {
            # 1.0x foveation scaling
            scale = 1.0;
            # 100 Mb/s
            bitrate = 100000000;
            encoders = [
              {
                encoder = "vaapi";
                codec = "h265";
                width = 0.125;
                height = 1.0;
                offset_x = 0.0;
                offset_y = 0.0;
                group = 0;
              }
              {
                encoder = "vaapi";
                codec = "h265";
                width = 0.375;
                height = 1.0;
                offset_x = 0.125;
                offset_y = 0.0;
                group = 0;
              }
              {
                encoder = "vaapi";
                codec = "h265";
                width = 0.5;
                height = 1.0;
                offset_x = 0.5;
                offset_y = 0.0;
                group = 0;
              }
            ];
            application = [ pkgs.wlx-overlay-s ];
          };
        };
      };
    };
  };
}
