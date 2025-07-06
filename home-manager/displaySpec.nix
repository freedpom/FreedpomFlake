{ lib, ... }:
{
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

            # Color depth
            colorDepth = lib.mkOption {
              type = lib.types.enum [
                8
                16
                24
                32
              ];
              default = 24;
              description = "Color depth in bits per pixel";
            };

            # VRR/Adaptive Sync
            variableRefreshRate = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable variable refresh rate (FreeSync/G-Sync)";
            };

            # HDR support
            hdr = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable HDR if supported by monitor";
            };

            # Flexible tagging system for monitor designation
            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of tags to categorize monitor usage";
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

            # Workspace assignment (for tiling WMs)
            workspaces = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of workspaces to assign to this monitor";
              example = [
                "1"
                "2"
                "3"
              ];
            };

          };
        }
      );
      default = { };
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
        };
      };
    };
  };
}
