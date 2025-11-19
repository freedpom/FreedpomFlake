{lib, ...}: {
  options.ff.hostConf = {
    tags = {
      description = ''
        Tags that define the host's role and characteristics, separated into distinct categories
        that can be combined without overlapping functionality.

        Each tag applies specific system configurations and can be combined with tags from other
        categories to create custom profiles for different use cases.

        Example combinations:
        ```nix
        # Gaming laptop with battery optimization
        ff.hostConf.tags = {
          compute = [ "gaming" ];
          power = [ "battery" ];
          environment = [ "mobile" ];
        };

        # Professional workstation for audio production
        ff.hostConf.tags = {
          compute = [ "creative" "audio" ];
          power = [ "performance" ];
          environment = [ "desktop" ];
        };

        # Home theater PC
        ff.hostConf.tags = {
          compute = [ "media" ];
          power = [ "efficiency" ];
          environment = [ "living-room" ];
        };

        # Headless server with minimal resources
        ff.hostConf.tags = {
          compute = [ "server" ];
          power = [ "efficiency" ];
          environment = [ "headless" ];
        };
        ```
      '';

      compute = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "gaming" # Gaming optimizations, Steam, gaming-specific drivers
            "office" # Office applications, document handling
            "server" # Server applications, databases, web services
          ]
        );
        default = [];
        example = [
          "development"
          "creative"
        ];
        description = ''
          Compute profiles define the primary computational tasks and software stacks.

          These tags influence which software packages are installed, kernel optimizations,
          filesystem configurations, and specialized tools for specific workflows.
        '';
      };

      power = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "performance" # Maximum performance, ignores power consumption
            "efficiency" # Balanced power/performance ratio
            "battery" # Maximize battery life on portable devices
          ]
        );
        default = ["efficiency"];
        example = ["performance"];
        description = ''
          Power profiles define how the system manages power and performance.

          These tags configure CPU governors, thermal settings, power management,
          and performance-related kernel parameters.
        '';
      };

      environment = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "desktop" # Standard desktop environment
            "mobile" # Laptop/portable device
            "tablet" # Tablet/convertible device
            "living-room" # Media center/HTPC setup
            "headless" # No graphical interface
            "industrial" # Industrial/embedded environment
          ]
        );
        default = ["desktop"];
        example = ["mobile"];
        description = ''
          Environment profiles define the physical context and form factor.

          These tags influence display settings, power management policies,
          network configurations, and other hardware-related settings.
        '';
      };

      special = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "kiosk" # Single-application display
            "accessibility" # Enhanced accessibility features
            "minimal" # Minimal resource usage
            "secure" # Enhanced security measures
            "realtime" # Realtime processing guarantees
          ]
        );
        default = [];
        example = ["kiosk"];
        description = ''
          Special profiles for specific use cases that require unique configurations.

          These tags enable specialized system configurations that don't fit into
          the other categories.
        '';
      };
    };

    # Removed performanceProfile option - now managed through tags.power

    uiMode = lib.mkOption {
      type = lib.types.enum [
        "touch" # Optimized for touch input - large targets, swipe gestures
        "pointer" # Optimized for mouse/trackpad/trackball - precise targeting
        "keyboard" # Optimized for keyboard navigation - clear focus indicators
        "tv" # Optimized for remote/distant viewing - very large UI, D-pad navigation
      ];
      default = "pointer";
      example = "touch";
      description = ''
        Determines the primary UI interaction mode, affecting component sizing and interaction patterns.

        This setting influences:
        - UI component sizes (button/target sizes)
        - Navigation patterns (visible focus, tab order)
        - Gesture support
        - Overall layout (compact vs. spacious)
        - Text size and readability

        Examples:

        ```nix
        # For a tablet or touchscreen device
        ff.hostConf.uiMode = "touch";

        # For a traditional desktop computer
        ff.hostConf.uiMode = "pointer";

        # For a media center/HTPC
        ff.hostConf.uiMode = "tv";

        # For a keyboard-centric tiling window manager setup
        ff.hostConf.uiMode = "keyboard";
        ```
      '';
    };
  };
}
