{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.ff.services.pipewire;
in
{

  options.ff.services.pipewire = {
    enable = lib.mkEnableOption "Enable PipeWire configuration to provide low-latency audio/video routing with pro-audio optimizations";

    # Documentation about latency values:
    # 32/48000 = ~0.67ms latency
    # 64/48000 = ~1.33ms latency
    # 128/48000 = ~2.67ms latency
    # 256/48000 = ~5.33ms latency
    # 512/48000 = ~10.67ms latency
    # 1024/48000 = ~21.33ms latency
  };

  config = lib.mkIf cfg.enable {
    # Enable threadirqs for better audio performance
    # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L76
    boot = lib.mkIf config.services.pipewire.enable { kernelParams = [ "threadirqs" ]; };

    environment.systemPackages = with pkgs; [
      alsa-utils
      pavucontrol
      playerctl
      qpwgraph
    ];

    services = {
      pipewire = {
        enable = true;
        audio.enable = true;
        # Audio subsystems
        alsa = {
          enable = true;
          support32Bit = lib.mkForce config.hardware.graphics.enable32Bit;
        };
        jack.enable = true;
        pulse.enable = true;

        wireplumber = {
          enable = true;
        };

        extraConfig = {
          pipewire = {
            "10-clock-rate" = {
              "context.properties" = {
                "default.clock.rate" = 48000;
                "default.clock.allowed-rates" = [
                  44100
                  48000
                  88200
                  96000
                ];
                "default.clock.quantum" = 1024;
                "default.clock.min-quantum" = 32;
                "default.clock.max-quantum" = 8192;
              };
            };
            "11-modules" = {
              "context.modules" = [
                {
                  name = "libpipewire-module-rtkit";
                  flags = [
                    "ifexists"
                    "nofail"
                  ];
                  args = {
                    nice.level = -15;
                    rt = {
                      prio = 88;
                      time.soft = 200000;
                      time.hard = 200000;
                    };
                  };
                }
                {
                  name = "libpipewire-module-protocol-pulse";
                  args = {
                    server.address = [ "unix:native" ];
                    pulse.min = {
                      req = "32/48000";
                      quantum = "32/48000";
                      frag = "32/48000";
                    };
                  };
                }
              ];
            };
            "12-stream" = {
              "context.stream.properties" = {
                node.latency = "32/48000";
                resample.quality = 1;
              };
            };
          };
        };
      };

      # Expose timers and cpu dma latency the members of the audio group
      # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L139
      udev.extraRules = ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
        DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
      '';
    };
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

}
