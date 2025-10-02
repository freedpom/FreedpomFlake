{
  lib,
  config,
  ...
}: {
  options = {
    ff.hardware.displays = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            resolution = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  width = lib.mkOption {
                    type = lib.types.int;
                    default = 1920;
                    description = "Width of the display in pixels.";
                    example = 2560;
                  };
                  height = lib.mkOption {
                    type = lib.types.int;
                    default = 1080;
                    description = "Height of the display in pixels.";
                    example = 1440;
                  };
                };
              };
              default = {};
              description = "Display resolution.";
            };

            framerate = lib.mkOption {
              type = lib.types.int;
              default = 60;
              description = "Refresh rate in Hz.";
              example = 144;
            };

            scale = lib.mkOption {
              type = lib.types.either lib.types.int lib.types.float;
              default = 1.0;
              description = "Scaling factor (1.0 = 100%, 1.5 = 150%, etc.).";
              example = 1.25;
            };

            position = lib.mkOption {
              type = lib.types.str;
              default = "auto";
              description = "Position of the display relative to others (e.g., '1920x0').";
              example = "3840x0";
            };

            transform = lib.mkOption {
              type = lib.types.enum [
                0
                1
                2
                3
              ];
              default = 0;
              description = ''
                Rotation of the display:
                0 = normal, 1 = 90°, 2 = 180°, 3 = 270°.
              '';
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
              description = "Color depth in bits per pixel.";
              example = 10;
            };

            vrr = lib.mkOption {
              type = lib.types.enum [
                0
                1
                2
                3
              ];
              default = 0;
              description = ''
                Variable refresh rate (VRR) mode:
                0 = disabled, 1 = enabled, 2 = automatic, 3 = force.
              '';
              example = 1;
            };

            mirror = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Name of another display to mirror.";
              example = "HDMI-1";
            };

            colorProfile = lib.mkOption {
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
              description = "Color management profile to apply.";
              example = "hdr";
            };

            sdrBrightness = lib.mkOption {
              type = lib.types.nullOr lib.types.float;
              default = null;
              description = "SDR brightness multiplier when HDR is enabled.";
              example = 1.2;
            };

            sdrSaturation = lib.mkOption {
              type = lib.types.nullOr lib.types.float;
              default = null;
              description = "SDR saturation multiplier when HDR is enabled.";
              example = 0.98;
            };

            workspaces = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Workspaces assigned to this display.";
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
      description = "Configuration for each connected display.";
      example = {
        "DP-1" = {
          resolution = {
            width = 2560;
            height = 1440;
          };
          framerate = 144;
          scale = 1.0;
          position = "0x0";
          transform = 0;
          color_depth = 10;
          vrr = 1;
          mirror = null;
          colorProfile = "hdr";
          sdrBrightness = 1.2;
          sdrSaturation = 0.98;
          workspaces = [
            "1"
            "2"
            "3"
          ];
        };
      };
    };
  };
  config = {
    boot.kernelParams = lib.mkForce (
      let
        displays = config.ff.hardware.displays or {};
        videoParams = builtins.attrValues (
          lib.mapAttrs (
            name: disp: "video=${name}:${toString disp.resolution.width}x${toString disp.resolution.height}@${toString disp.framerate}"
          )
          displays
        );
      in
        videoParams ++ (config.system.kernelParams or [])
    );
  };
}
