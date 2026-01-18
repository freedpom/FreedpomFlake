{
  flake.nixosModules.default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.services.consoles;

      # TODO: Integrate with Stylix for automatic color scheme and font application
      # Will need: config.lib.stylix.colors conversion to RGB tuples for kmscon palette

      # Extract TTY number from string (e.g., "tty1" -> "1")
      extractTtyNum =
        ttyStr:
        let
          tty = builtins.match ".*tty([0-9]+).*" ttyStr;
        in
        if tty != null then builtins.head tty else null;

      # Extract username from autologin string (e.g., "user@tty1" -> "user")
      extractUser =
        str:
        let
          user = builtins.match "([^@]+)@.*" str;
        in
        if user != null then builtins.head user else null;

      # Parse TTY specification into structured data
      parseTtySpec = spec: {
        tty = extractTtyNum spec;
        user = extractUser spec;
        autologin = builtins.match ".*@.*" spec != null;
      };

      # Generate default TTY list when bool is true
      generateDefaultTtys = count: map (i: "tty${toString i}") (lib.range 1 count);

      # Normalize TTY configuration to list format
      normalizeTtyConfig =
        config:
        if lib.isBool config then
          if config then generateDefaultTtys 6 else [ ]
        else if lib.isList config then
          config
        else
          throw "Invalid TTY configuration type";

      # Process TTY configurations
      gettyTtys = normalizeTtyConfig cfg.getty;
      kmsconTtys = normalizeTtyConfig cfg.kmscon;
      allTtys = gettyTtys ++ kmsconTtys;

      # Parse all TTY specifications

      # Create systemd service for getty
      createGettyService =
        spec:
        let
          parsed = parseTtySpec spec;
          ttyNum = parsed.tty;
          inherit (parsed) user;
        in
        lib.nameValuePair "getty@tty${ttyNum}" {
          enable = true;
          serviceConfig = {
            ExecStart = lib.mkForce (
              if parsed.autologin && user != null then
                "${lib.getExe' pkgs.util-linux "agetty"} --login-program ${pkgs.shadow}/bin/login --autologin ${user} --noclear %I $TERM"
              else
                "${lib.getExe' pkgs.util-linux "agetty"} --login-program ${pkgs.shadow}/bin/login --noclear %I $TERM"
            );
            Type = "idle";
            Restart = "always";
            RestartSec = "0";
          };
          wantedBy = [ "multi-user.target" ];
        };

      createSpawnService =
        spec:
        let
          parsed = parseTtySpec spec;
          ttyNum = parsed.tty;
          inherit (parsed) user;
          spawnCfg = cfg.spawn.${spec};
          inherit (spawnCfg) execStart;
        in
        lib.nameValuePair "spawn@tty${ttyNum}" {
          enable = true;
          serviceConfig = {
            Type = "simple";
            ExecStart = lib.mkForce "${execStart}";
            ExecStop = "/bin/kill -HUP \${MAINPID}";
            StandardInput = "tty";
            StandardOutput = "tty";
            TTYPath = "/dev/tty${ttyNum}";
            #TTYReset = true;
            #TTYVHangup = true;
            #TTYVTDisallocate = true;
            Restart = "always";
            RestartSec = "2";
            User = user;
            Environment = "XDG_RUNTIME_DIR=/run/user/${toString config.users.users.${user}.uid}";
          };
          wantedBy = [ "getty.target" ];
        };

      # TODO: Convert Stylix hex colors to RGB tuples for kmscon palette
      # Example: "--palette-black=255, 255, 255" for RGB values

      # Build kmscon command arguments
      buildKmsconArgs =
        kmsconConfig:
        let
          fontName = kmsconConfig.font.name;
          fontSize = kmsconConfig.font.size;
        in
        [
          "--vt"
          "%I"
          "--no-switchvt"
          "--login"
        ]
        ++ (lib.optional (fontName != null) "--font-name=${fontName}")
        ++ (lib.optional (fontSize != null) "--font-size=${toString fontSize}")
        ++ (lib.optional (kmsconConfig.font.dpi != null) "--font-dpi=${toString kmsconConfig.font.dpi}")
        ++ (lib.optional (!kmsconConfig.hwaccel) "--no-hwaccel")
        ++ (lib.optional (!kmsconConfig.drm) "--no-drm")
        ++ (lib.optional (kmsconConfig.palette != "default") "--palette=${kmsconConfig.palette}")
        ++ (lib.optional (
          kmsconConfig.scrollbackSize != null
        ) "--sb-size=${toString kmsconConfig.scrollbackSize}")
        # Video/Display options
        ++ (lib.optional (kmsconConfig.video.gpus != "all") "--gpus=${kmsconConfig.video.gpus}")
        ++ (lib.optional (
          kmsconConfig.video.renderEngine != null
        ) "--render-engine=${kmsconConfig.video.renderEngine}")
        ++ (lib.optional kmsconConfig.video.renderTiming "--render-timing")
        ++ (lib.optional (!kmsconConfig.video.useOriginalMode) "--no-use-original-mode")
        # TODO: Add Stylix color arguments when integration is available
        ++ kmsconConfig.extraArgs;

      # Create systemd service for kmscon
      createKmsconService =
        spec:
        let
          parsed = parseTtySpec spec;
          ttyNum = parsed.tty;
          inherit (parsed) user;
          kmsconArgs = buildKmsconArgs cfg.kmsconConfig;
          argsStr = lib.concatStringsSep " " kmsconArgs;
        in
        lib.nameValuePair "kmsconvt@tty${ttyNum}" {
          enable = true;
          serviceConfig = {
            ExecStart = lib.mkForce (
              if parsed.autologin && user != null then
                "${lib.getExe pkgs.kmscon} ${argsStr} -- ${pkgs.shadow}/bin/login -f ${user}"
              else
                "${lib.getExe pkgs.kmscon} ${argsStr} -- ${pkgs.shadow}/bin/login"
            );
            Type = "simple";
            Restart = "always";
            RestartSec = "0";
          };
          wantedBy = [ "multi-user.target" ];
        };

      # Validation functions
      validateTtyFormat = spec: extractTtyNum spec != null || throw "Invalid TTY format: ${spec}";

      validateUserExists =
        spec:
        let
          user = extractUser spec;
        in
        if user != null then user != "" || throw "Empty username in: ${spec}" else true;
    in
    {
      options.freedpom.services.consoles = {
        enable = lib.mkEnableOption "console services configuration";

        getty = lib.mkOption {
          type = lib.types.either lib.types.bool (
            lib.types.listOf (lib.types.strMatching "^(tty[0-9]+|[a-zA-Z0-9]+@tty[0-9]+)$")
          );
          default = false;
          description = lib.mdDoc ''
            Configure getty on TTYs.

            - `true`: Enable on tty1-tty6
            - `false`: Disable
            - List: Enable on specified TTYs (e.g., ["tty1" "user@tty2"])

            Use "user@ttyN" format for autologin.
          '';
          example = [
            "user@tty1"
            "tty2"
            "tty3"
          ];
        };

        kmscon = lib.mkOption {
          type = lib.types.either lib.types.bool (
            lib.types.listOf (lib.types.strMatching "^(tty[0-9]+|[a-zA-Z0-9]+@tty[0-9]+)$")
          );
          default = false;
          description = lib.mdDoc ''
            Configure kmscon on TTYs.

            - `true`: Enable on tty1-tty6
            - `false`: Disable
            - List: Enable on specified TTYs (e.g., ["tty1" "user@tty2"])

            Use "user@ttyN" format for autologin.
          '';
          example = [
            "user@tty1"
            "tty2"
          ];
        };

        spawn = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                execStart = lib.mkOption {
                  type = lib.types.str;
                };
              };
            }
          );
          default = { };
          description = lib.mdDoc ''
            Run a package on a specific TTY instead of getty/kmscon.
            The attribute name must be in the format `user@ttyN`.

            Example:
            ```nix
            spawn = {
              "myuser@tty7" = {
                package = pkgs.bottom;
                args = [];
              };
            };
            ```
          '';
        };

        kmsconConfig = lib.mkOption {
          type = lib.types.submodule {
            options = {
              font = {
                name = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Font name for kmscon";
                  example = "monospace";
                };
                size = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.positive;
                  default = null;
                  description = "Font size in points";
                  example = 12;
                };
                dpi = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.positive;
                  default = null;
                  description = "DPI value for fonts";
                  example = 96;
                };
              };
              hwaccel = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable 3D hardware acceleration";
              };
              drm = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Use DRM if available";
              };
              palette = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = "Color palette to use";
                example = "solarized";
              };
              scrollbackSize = lib.mkOption {
                type = lib.types.nullOr lib.types.ints.positive;
                default = null;
                description = "Scrollback buffer size in lines";
                example = 1000;
              };
              video = {
                gpus = lib.mkOption {
                  type = lib.types.enum [
                    "all"
                    "aux"
                    "primary"
                  ];
                  default = "all";
                  description = "GPU selection mode";
                };
                renderEngine = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Console renderer engine";
                  example = "gltex";
                };
                renderTiming = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Print renderer timing information";
                };
                useOriginalMode = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Use original KMS video mode";
                };
              };
              extraArgs = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = lib.mdDoc ''
                  Additional arguments to pass to kmscon.

                  Useful for display-specific settings like:
                  - `"--seats=seat0:card0-HDMI-A-1"` - Use specific output
                  - Custom resolution or display configurations
                '';
                example = [
                  "--xkb-layout=us"
                  "--xkb-variant=colemak"
                  "--seats=seat0:card0-HDMI-A-1"
                ];
              };
            };
          };
          default = { };
          description = "Kmscon configuration options";
        };

        # stylix = {
        #   enable = mkOption {
        #     type = types.bool;
        #     default = config.stylix.enable or false;
        #     description = "Enable Stylix integration for kmscon colors and fonts";
        #   };
        # };
      };

      config = lib.mkIf cfg.enable {
        console.useXkbConfig = lib.mkDefault true;

        # Create systemd services
        systemd.services =
          (lib.listToAttrs (map createGettyService gettyTtys))
          // (lib.listToAttrs (map createKmsconService kmsconTtys))
          // (lib.listToAttrs (map createSpawnService (lib.attrNames cfg.spawn)))
          # Disable default getty services
          // {
            "autovt@".enable = false;
            "getty@".enable = false;
          };

        # System assertions for validation
        assertions = [
          {
            assertion =
              lib.length gettyTtys == 0
              || lib.length kmsconTtys == 0
              ||
                lib.length (lib.intersectLists (map extractTtyNum gettyTtys) (map extractTtyNum kmsconTtys)) == 0;
            message = "Getty and kmscon cannot be configured on same TTY";
          }
          {
            assertion = lib.all (
              spec:
              let
                tty = extractTtyNum spec;
              in
              !(lib.elem "tty${tty}" gettyTtys || lib.elem "tty${tty}" kmsconTtys)
            ) (lib.attrNames cfg.spawn);
            message = "Spawned services cannot share TTYs with getty or kmscon";
          }
          {
            assertion = lib.all validateTtyFormat allTtys;
            message = "All TTY specifications must contain 'ttyN' format";
          }
          {
            assertion = lib.all validateUserExists allTtys;
            message = "Autologin specifications must have valid usernames";
          }
          {
            assertion = !(lib.isList cfg.getty && lib.length cfg.getty == 0);
            message = "Getty cannot be set to empty list";
          }
          {
            assertion = !(lib.isList cfg.kmscon && lib.length cfg.kmscon == 0);
            message = "Kmscon cannot be set to empty list";
          }
          {
            assertion = !config.services.kmscon.enable;
            message = "Please do not enable consoles externally";
          }
        ];
      };
    };
}
