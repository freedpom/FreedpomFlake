{lib, ...}: {
  options = {
    ff.hardware.videoPorts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
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

            framerate = lib.mkOption {
              type = lib.types.int;
              default = 60;
              description = "Display refresh rate in Hz";
              example = 144;
            };

            scale = lib.mkOption {
              type = lib.types.either lib.types.int lib.types.float;
              default = 1.0;
              description = "Display scaling factor (1.0 = 100%, 1.5 = 150%, etc.)";
              example = 1.25;
            };

            position = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              description = "Coordinate of monitor position";
              example = "3840x0";
            };

            transform = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Rotate a monitor (0=normal, 1=90°, 2=180°, etc.)";
              example = 1;
            };

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

            vrr = lib.mkOption {
              type = lib.types.enum [
                0
                1
                2
                3
              ];
              default = 0;
              description = "Enable variable refresh rate (VRR)";
            };

            mirror = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Name of monitor to mirror this display to";
            };

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

            sdrbrightness = lib.mkOption {
              type = lib.types.nullOr lib.types.float;
              default = null;
              description = "SDR brightness multiplier when HDR is enabled";
              example = 1.2;
            };

            sdrsaturation = lib.mkOption {
              type = lib.types.nullOr lib.types.float;
              default = null;
              description = "SDR saturation multiplier when HDR is enabled";
              example = 0.98;
            };

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
          variableRefreshRate = true;
          cm = "hdr";
          sdrbrightness = 1.2;
          sdrsaturation = 0.98;
          workspaces = [
            "1"
            "2"
            "3"
          ];
        };
      };
    };
  };
}
