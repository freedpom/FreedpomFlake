{
  flake.nixosModules.default =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.services.pipewire;
    in
    {
      options.freedpom.services.pipewire = {
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
        # Thread IRQs required for real-time audio performance
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
        };
      };
    };
}
