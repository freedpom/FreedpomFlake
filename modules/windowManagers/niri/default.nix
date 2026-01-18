{
  flake.nixosModules.windowManagers =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.windowManagers.niri;
    in
    {
      options.freedpom.windowManagers.niri = {
        enable = lib.mkEnableOption "Niri scrollable tiling Wayland compositor";
      };

      config = lib.mkIf cfg.enable {
        programs = {
          niri = {
            enable = true;
          };
          xwayland.enable = true;
        };

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };

        # Optional: Use overlay for niri-unstable if needed
        # nixpkgs.overlays = [ inputs.niri.overlays.niri ];
        # programs.niri.package = pkgs.niri-unstable;
      };
    };

  flake.homeModules.windowManagers =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.freedpom.windowManagers.niri;
    in
    {
      options.freedpom.windowManagers.niri = {
        enable = lib.mkEnableOption "Niri user configuration";
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          wl-clipboard
          wofi
          mako
          waybar
        ];

        # Example Niri configuration
        programs.niri.settings = {
          outputs = {
            "eDP-1" = {
              mode = {
                width = 1920;
                height = 1080;
                refresh = 60.0;
              };
              position = {
                x = 0;
                y = 0;
              };
            };
          };

          input = {
            keyboard = {
              repeat-delay = 600;
              repeat-rate = 25;
              track-layout = "global";
            };

            touchpad = {
              tap = true;
              dwt = true;
              natural-scroll = true;
            };

            mouse = {
              accel-speed = 0.0;
            };
          };

          layout = {
            focus-ring = {
              enable = true;
              width = 4;
            };

            border = {
              enable = true;
              width = 2;
            };
          };

          prefer-no-csd = true;
        };

        wayland = {
          windowManager.niri = {
            enable = true;
            settings = { };
          };
        };
      };
    };
}
