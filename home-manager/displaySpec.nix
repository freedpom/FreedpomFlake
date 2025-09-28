{lib, ...}: {
  options = {
    ff.hardware.videoPorts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            # Display resolution configuration
            resolution = {
              width = lib.mkOption {
                type = lib.types.int;
                default = 1920;
                description = "Display width in pixels";
                example = 2560;
              };
              height = lib.mkOption {
                type = lib.types.int;
                default = 1080;
                description = "Display height in pixels";
                example = 1440;
              };
            };

            # Display refresh rate
            framerate = lib.mkOption {
              type = lib.types.int;
              default = 60;
              description = "Display refresh rate in Hz";
              example = 144;
            };

            # Display scaling factor
            scale = lib.mkOption {
              type = lib.types.either lib.types.int lib.types.float;
              default = 1.0;
              description = "Display scaling factor (1.0 = 100%, 1.5 = 150%, etc.)";
              example = 1.25;
            };

            # Monitor position in multi-monitor setup
            position = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              description = "Coordinate of monitor position";
              example = "3840x0";
            };

            # Rotate a monitor
            transform = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Rotate a monitor (0=normal, 1=90°, 2=180°, etc.)";
              example = 1;
            };

            # Color depth (8,16,24,32, or 10 for 10-bit)
            colorDepth = lib.mkOption {
              type = lib.types.enum [
                8
                10
                16
                24
                32
              ];
              default = 24;
              description = "Color depth in bits per pixel";
            };

            # Enable variable refresh rate (FreeSync/G-Sync)
            variableRefreshRate = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable variable refresh rate (VRR)";
            };

            # HDR support flag
            hdr = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable HDR if supported";
            };

            # Mirror this monitor to another by name
            mirror = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Name of monitor to mirror this display to";
            };

            # Color management preset
            cm = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.enum [
                  "auto"
                  "srgb"
                  "wide"
                  "edid"
                  "hdr"
                  "hdredid"
                ]
              );
              default = null;
              description = "Color management preset for the monitor";
            };

            # SDR brightness multiplier (for HDR mode)
            sdrbrightness = lib.mkOption {
              type = lib.types.nullOr lib.types.float;
              default = null;
              description = "SDR brightness multiplier when HDR is enabled";
              example = 1.2;
            };

            # SDR saturation multiplier (for HDR mode)
            sdrsaturation = lib.mkOption {
              type = lib.types.nullOr lib.types.float;
              default = null;
              description = "SDR saturation multiplier when HDR is enabled";
              example = 0.98;
            };

            # Tags for categorizing monitor usage
            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Tags to categorize monitor usage";
              example = [
                "primary"
                "gaming"
                "media"
                "communication"
                "work"
                "vertical"
                "secondary"
              ];
            };

            # Workspaces assigned to this monitor
            workspaces = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "List of workspaces assigned to this monitor";
              example = [
                "1"
                "2"
                "3"
              ];
            };
          };
        }
      );
      default = {};
      description = "Configuration for video ports and connected displays";
      example = {
        DP-1 = {
          resolution = {
            width = 2560;
            height = 1440;
          };
          framerate = 144;
          scale = 1.0;
          tags = [
            "primary"
            "gaming"
            "media"
          ];
          enable = true;
          variableRefreshRate = true;
          workspaces = [
            "1"
            "2"
            "3"
          ];
          mirror = null;
          colorDepth = 10;
          cm = "wide";
          sdrbrightness = 1.2;
          sdrsaturation = 0.98;
        };
      };
    };
  };
}
