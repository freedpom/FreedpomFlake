{ lib, ... }:
{
  options = {
    ff.hardware.displays = lib.mkOption {
      description = ''
        Hardware Display Configuration

        This option allows you to define multiple displays with their
        physical and logical properties, including position, resolution,
        refresh rate, scaling, rotation, VRR settings, and more.

        Example configuration:
        ```nix
        ff.hardware.displays = [
          {
            # Main display
            name = "DP-1";
            port = "DP-1";
            resWidth = 3440;
            resHeight = 1440;
            refreshRate = 144;
            isPrimary = true;
            position = { x = 0; y = 0; };
            scale = 1.0;
            rotation = "normal";
            enableVRR = true;
            colorDepth = 24;
            ownedWorkspaces = [ 1 2 3 4 5 ];
          }
          {
            # Secondary vertical display
            name = "HDMI-1";
            port = "HDMI-1";
            resWidth = 1920;
            resHeight = 1080;
            refreshRate = 60;
            position = { x = 3440; y = 180; };
            scale = 1.0;
            rotation = "right";
            enableVRR = false;
            ownedWorkspaces = [ 6 7 8 ];
          }
        ];
        ```
      '';
      type = lib.types.listOf lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Display name (e.g., 'Main Display', 'Left Monitor'). If null, port name will be used.";
            example = "Main Display";
          };

          port = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Physical display port (e.g., 'HDMI-1', 'DP-2')";
            example = "HDMI-1";
          };

          # Resolution settings
          resWidth = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Display width in pixels";
            example = 1920;
          };

          resHeight = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Display height in pixels";
            example = 1080;
          };

          # Refresh rate settings
          refreshRate = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Refresh rate in Hz";
            example = 144;
          };

          enableVRR = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Variable Refresh Rate (FreeSync/G-Sync)";
          };

          vrrMinRate = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Minimum refresh rate for VRR in Hz. Only used if enableVRR is true.";
            example = 48;
          };

          vrrMaxRate = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Maximum refresh rate for VRR in Hz. Only used if enableVRR is true. Defaults to refreshRate if null.";
            example = 144;
          };

          # Layout and position settings
          position = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  x = lib.mkOption {
                    type = lib.types.int;
                    default = 0;
                    description = "X coordinate in the display layout";
                  };
                  y = lib.mkOption {
                    type = lib.types.int;
                    default = 0;
                    description = "Y coordinate in the display layout";
                  };
                };
              }
            );
            default = null;
            description = "Position of the display in the multi-monitor layout";
            example = {
              x = 1920;
              y = 0;
            };
          };

          isPrimary = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this is the primary display";
          };

          scale = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
            description = "Display scaling factor";
            example = 1.5;
          };

          rotation = lib.mkOption {
            type = lib.types.enum [
              "normal"
              "left"
              "right"
              "inverted"
            ];
            default = "normal";
            description = "Display rotation";
            example = "right";
          };

          # Color settings
          colorDepth = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                8
                16
                24
                30
              ]
            );
            default = 24;
            description = "Color depth in bits (8, 16, 24, or 30)";
            example = 30;
          };

          gamma = lib.mkOption {
            type = lib.types.nullOr lib.types.float;
            default = 1.0;
            description = "Gamma correction value";
            example = 0.9;
          };

          # Workspace assignment
          ownedWorkspaces = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.int);
            default = null;
            description = "List of workspace IDs assigned to this display";
            example = [
              1
              2
              3
              4
            ];
          };

          # Mode and timing settings (advanced)
          mode = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Custom display mode (use instead of resWidth/resHeight/refreshRate for custom timings)";
            example = "1920x1080@60.00";
          };

          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether the display should be enabled";
          };
        };
      };
      default = [ ];
    };
  };
}
