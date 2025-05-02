{
  lib,
  ...
}:
{
  options.ff.hostConf = {
    displayType = {
      description = ''
        Configuration options for the display server and console setup.

        Example:
        ```nix
        ff.hostConf.displayType = {
          wayland = true;
          kmscon = [ 1 2 3 ];
        };
        ```
      '';

      headless = lib.mkEnableOption "Headless mode (no graphical interface)";

      x11 = lib.mkEnableOption "Enable X11 display server";

      wayland = lib.mkEnableOption "Enable Wayland display server";

      kmscon = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        example = [
          1
          2
          3
        ];
        description = "List of TTYs that will be enabled with KMS console";
      };
    };

    tags = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "power-save" # Laptops & small arm devices
          "gaming" # High performance gaming
          "rt-audio" # Real-time audio
          "server" # Server-oriented configuration
          "workstation" # Desktop workstation
          "media-center" # Media center/HTPC
          "kiosk" # Kiosk/single-application display
          "development" # Development environment
        ]
      );
      default = [ ];
      example = [
        "gaming"
        "rt-audio"
      ];
      description = ''
        Tags that define the host's role and characteristics.

        These tags influence various system settings like CPU frequency scaling,
        kernel parameters, power management, and more.

        Example:
        ```nix
        ff.hostConf.tags = [ "power-save" "development" ];
        ```
      '';
    };

    performanceProfile = lib.mkOption {
      type = lib.types.enum [
        "balanced" # Default balanced performance and power usage
        "performance" # Maximum performance, higher power usage
        "power-saver" # Maximum battery life, reduced performance
        "low-latency" # Optimized for low-latency applications like audio/gaming
      ];
      default = "balanced";
      example = "performance";
      description = ''
        Performance profile for the system.

        This affects CPU governor, kernel settings, power management,
        and other performance-related configurations.

        Note: This can be overridden by specific tags. For example,
        the "gaming" tag will imply "performance" profile settings, and
        "power-save" tag will imply "power-saver" profile settings unless 
        explicitly configured otherwise.
      '';
    };

    inputDevices = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [
                "controller" # Game controller
                "keyboard" # Standard keyboard
                "mouse" # Standard mouse
                "touch" # Touchscreen
                "trackpad" # Laptop trackpad
                "tablet" # Graphics tablet
                "trackball" # Trackball pointer
                "joystick" # Joystick
                "remote" # Remote control
              ];
              description = "Type of input device";
              example = "mouse";
            };

            primary = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this is the primary input device of its type";
            };

            name = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional device name for identification";
              example = "Logitech G502";
            };

            config = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
              description = "Additional device-specific configuration";
              example = {
                sensitivity = 0.8;
                accelProfile = "flat";
              };
            };
          };
        }
      );
      default = [
        {
          type = "keyboard";
          primary = true;
        }
      ];
      example = [
        {
          type = "keyboard";
          primary = true;
          name = "Main Keyboard";
        }
        {
          type = "mouse";
          primary = true;
          name = "Gaming Mouse";
          config = {
            sensitivity = 0.8;
          };
        }
        {
          type = "controller";
          name = "Xbox Controller";
        }
      ];
      description = ''
        Configure the system for various input devices.

        This affects UI behavior, input settings, and device-specific configurations.

        Example:
        ```nix
        ff.hostConf.inputDevices = [
          { type = "keyboard"; primary = true; }
          { type = "mouse"; primary = true; }
          { type = "touch"; }
        ];
        ```
      '';
    };

    # Legacy option kept for backward compatibility
    inputType = lib.mkOption {
      type = lib.types.enum [
        "controller"
        "keyboard"
        "mouse"
        "touch"
        "trackpad"
      ];
      default = "keyboard";
      example = "mouse";
      description = ''
        DEPRECATED: Use inputDevices instead.
        Legacy option for configuring the primary input device.
      '';
    };
  };
}
