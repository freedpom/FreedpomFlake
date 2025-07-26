{
  config,
  lib,
  ...
}:
let
  cfg = config.ff.services.virt-reality;
in
{
  # Configuration options for Ananicy service
  options.ff.services.virt-reality = {
    enable = lib.mkEnableOption "Enable the virtual reality";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      "opencomposite"
      "wlx-overlay-s"
    ];
    services = {
      wivrn = {
        enable = true;
        defaultRuntime = true;

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
                # 1.0 x 1.0 scaling
                width = 1.0;
                height = 1.0;
                offset_x = 0.0;
                offset_y = 0.0;
              }
            ];
          };
        };
      };
    };
  };
}
