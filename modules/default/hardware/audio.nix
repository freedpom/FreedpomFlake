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
        enable = lib.mkEnableOption "Enable audio hardware configuration for low-latency audio";
      };

      config = lib.mkIf cfg.enable {
        # Expose timers and cpu dma latency to members of the audio group
        # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L139
        services.udev.extraRules = ''
          KERNEL=="rtc0", GROUP="audio"
          KERNEL=="hpet", GROUP="audio"
          DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        '';

        # Allow members of the "audio" group to set RT priorities
        # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L112
        security = {
          pam.loginLimits = [
            # Memory limits
            {
              domain = "@audio";
              item = "memlock";
              type = "-";
              value = "unlimited";
            }
            # File limits
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
            # Realtime priority limits
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