{
  flake.nixosModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.hardware.audio;
    in
    {
      options.freedpom.hardware.audio = {
        enable = lib.mkEnableOption "Audio hardware configuration for low-latency audio production with real-time priorities and memory optimization";
      };

      config = lib.mkIf cfg.enable {

        services.udev.extraRules = ''
          KERNEL=="rtc0", GROUP="audio"
          KERNEL=="hpet", GROUP="audio"
          DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        '';

        security = {
          pam.loginLimits = [
            {
              domain = "@audio";
              item = "memlock";
              type = "-";
              value = "unlimited";
            }
            {
              domain = "@audio";
              item = "nofile";
              type = "hard";
              value = "99999";
            }
            {
              domain = "@audio";
              item = "nofile";
              type = "soft";
              value = "99999";
            }
            {
              domain = "@audio";
              item = "rtprio";
              type = "-";
              value = "99";
            }
          ];
          rtkit.enable = true;
        };
      };
    };
}
