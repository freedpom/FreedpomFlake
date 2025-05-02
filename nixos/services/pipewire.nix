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
        # Audio subsystems
        alsa = {
          enable = true;
          support32Bit = lib.mkForce config.hardware.graphics.enable32Bit;
        };
        jack.enable = false;
        pulse.enable = true;
        # Low-latency daemon configuration
        extraConfig.pipewire = {
          "context.properties" = {
            # Core properties
            "link.max-buffers" = 16; # Version < 3 clients can't handle more than this
            "log.level" = 2; # Warning level
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32; # Low-latency quantum (buffer size)
            "default.clock.min-quantum" = 32; # Minimum buffer size
            "default.clock.max-quantum" = 8192; # Maximum buffer size
            "core.daemon" = true;
            "core.name" = "pipewire-0";
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rtkit";
              args = {
                "nice.level" = -15;
                "rt.prio" = 88;
                "rt.time.soft" = 200000;
                "rt.time.hard" = 200000;
              };
              flags = [
                "ifexists"
                "nofail"
              ];
            }
            { name = "libpipewire-module-protocol-native"; }
            { name = "libpipewire-module-profiler"; }
            { name = "libpipewire-module-metadata"; }
            { name = "libpipewire-module-spa-device-factory"; }
            { name = "libpipewire-module-spa-node-factory"; }
            { name = "libpipewire-module-client-node"; }
            { name = "libpipewire-module-client-device"; }
            {
              name = "libpipewire-module-portal";
              flags = [
                "ifexists"
                "nofail"
              ];
            }
            {
              name = "libpipewire-module-access";
              args = { };
            }
            { name = "libpipewire-module-adapter"; }
            { name = "libpipewire-module-link-factory"; }
            { name = "libpipewire-module-session-manager"; }
          ];
        };
        # Low-latency ALSA configuration
        extraConfig."pipewire-pulse" = {
          "context.properties" = {
            "log.level" = 2;
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rtkit";
              args = {
                "nice.level" = -15;
                "rt.prio" = 88;
                "rt.time.soft" = 200000;
                "rt.time.hard" = 200000;
              };
              flags = [
                "ifexists"
                "nofail"
              ];
            }
            { name = "libpipewire-module-protocol-native"; }
            { name = "libpipewire-module-client-node"; }
            { name = "libpipewire-module-adapter"; }
            { name = "libpipewire-module-metadata"; }
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                "pulse.min.req" = "32/48000"; # 0.67ms
                "pulse.default.req" = "32/48000"; # 0.67ms
                "pulse.max.req" = "32/48000"; # 0.67ms
                "pulse.min.frag" = "32/48000"; # 0.67ms
                "pulse.default.frag" = "32/48000"; # 0.67ms
                "pulse.max.frag" = "32/48000"; # 0.67ms
                "pulse.min.quantum" = "32/48000"; # 0.67ms
              };
            }
          ];
          "stream.properties" = {
            "node.latency" = "32/48000"; # 0.67ms
            "resample.quality" = 1;
          };
        };
        # Session manager with low-latency configuration
        wireplumber = {
          enable = true;
          # Low-latency Wireplumber configuration
          extraConfig = {
            wireplumber = {
              "wireplumber.conf" = ''
                context.properties = {
                  log.level = 2
                }

                wireplumber.profiles = {
                  main = {
                    monitor.bluez = true
                  }
                }
              '';
              # Configure session settings for low latency
              "main.lua.d/51-disable-suspension.lua" = ''
                table.insert (alsa_monitor.rules, {
                  matches = {
                    {
                      -- Disable suspension for all audio devices
                      { "node.name", "matches", "alsa_input.*" },
                      { "node.name", "matches", "alsa_output.*" },
                    },
                  },
                  apply_properties = {
                    ["session.suspend-timeout-seconds"] = 0,  -- 0 disables suspend
                  },
                })
              '';
              # Blacklist problematic "front:6c" device
              "main.lua.d/99-alsa-blacklist.lua" = ''
                alsa_monitor.blacklist = {
                  -- Blacklist the problematic device
                  { matches = {{ "node.name", "matches", "alsa_card.*front:6c*" }} },
                }
              '';
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
