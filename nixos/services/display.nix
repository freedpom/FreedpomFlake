{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.ff.services.display;
  hostCfg = config.ff.hostConf;
  displayCfg = config.ff.hardware.displays;

  # Helper for getting primary display
  primaryDisplay =
    let
      primaryDisplays = filter (d: d.isPrimary) displayCfg;
    in
    if primaryDisplays != [ ] then
      head primaryDisplays
    else if displayCfg != [ ] then
      head displayCfg
    else
      null;

  # Helper for enabled displays
  enabledDisplays = filter (d: d.enabled) displayCfg;

  # Generate framebuffer resolution for console
  fbResolution =
    if
      primaryDisplay != null && primaryDisplay.resWidth != null && primaryDisplay.resHeight != null
    then
      "${toString primaryDisplay.resWidth}x${toString primaryDisplay.resHeight}"
    else
      "auto";

  # Configure kmscon with sensible defaults
  kmsconEnabled = hostCfg.displayType.kmscon != [ ];

  # Generate xorg.conf for manual X11 configuration
  xorgConfFile = pkgs.writeText "xorg.conf" (
    if enabledDisplays == [ ] then
      ""
    else
      ''
        Section "ServerLayout"
          Identifier "Default Layout"
          Screen 0 "Screen0" 0 0
        EndSection

        Section "Screen"
          Identifier "Screen0"
          Device "Device0"
          ${optionalString
            (primaryDisplay != null && primaryDisplay.resWidth != null && primaryDisplay.resHeight != null)
            ''
              SubSection "Display"
                Modes "${toString primaryDisplay.resWidth}x${toString primaryDisplay.resHeight}"
              EndSubSection
            ''
          }
        EndSection

        Section "Device"
          Identifier "Device0"
          Option "DPMS" "true"
        EndSection

        Section "ServerFlags"
          Option "BlankTime" "10"
          Option "StandbyTime" "20"
          Option "SuspendTime" "30"
          Option "OffTime" "60"
        EndSection

        # Input configuration
        Section "InputClass"
          Identifier "libinput pointer catchall"
          Driver "libinput"
          MatchIsPointer "on"
          MatchDevicePath "/dev/input/event*"
          Option "AccelProfile" "adaptive"
          Option "AccelSpeed" "0.3"
        EndSection

        Section "InputClass"
          Identifier "libinput keyboard catchall"
          Driver "libinput"
          MatchIsKeyboard "on"
          MatchDevicePath "/dev/input/event*"
        EndSection

        ${optionalString
          (any (
            d:
            elem d.type [
              "trackpad"
              "touch"
            ]
          ) hostCfg.inputDevices)
          ''
            Section "InputClass"
              Identifier "libinput touchpad catchall"
              Driver "libinput"
              MatchIsTouchpad "on"
              MatchDevicePath "/dev/input/event*"
              Option "Tapping" "on"
              Option "NaturalScrolling" "true"
              Option "ClickMethod" "clickfinger"
            EndSection
          ''
        }

        ${optionalString (any (d: d.enableVRR) enabledDisplays) ''
          Section "Device"
            Identifier "AMD"
            Driver "amdgpu"
            Option "VariableRefresh" "true"
          EndSection

          Section "Device"
            Identifier "NVIDIA"
            Driver "nvidia"
            Option "AllowVRR" "1"
          EndSection
        ''}
      ''
  );

in
{
  options.ff.services.display = {
    enable = mkEnableOption "Display services configuration";

    displayManager = mkOption {
      type = types.enum [
        "gdm"
        "sddm"
        "lightdm"
        "none"
      ];
      default = "sddm";
      description = "Display manager to use";
      example = "gdm";
    };

    autologin = {
      enable = mkEnableOption "Automatic login";

      user = mkOption {
        type = types.str;
        default = "nixos";
        description = "User to automatically log in";
        example = "user";
      };
    };

    extraXorgOptions = mkOption {
      type = types.lines;
      default = "";
      description = "Extra options to add to xorg.conf";
      example = ''
        Section "InputClass"
          Identifier "mouse"
          Driver "libinput"
          MatchIsPointer "on"
          Option "AccelProfile" "flat"
        EndSection
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base display configuration
    {
      # Configure boot console resolution
      boot.kernelParams = mkIf (primaryDisplay != null) [
        "video=${fbResolution}"
      ];

      # Enable kmscon if configured in hostConf
      ff.services.kmscon = {
        enable = kmsconEnabled;
        disableAt = optionals kmsconEnabled (map (tty: "tty${toString tty}") hostCfg.displayType.kmscon);
      };

      # Configure X server based on hostConf
      services.xserver = mkIf (!hostCfg.displayType.headless) {
        enable = hostCfg.displayType.x11 || (!hostCfg.displayType.wayland);

        # Basic X server configuration
        exportConfiguration = true;
        config = xorgConfFile;

        # Input devices configuration
        libinput = {
          enable = any (
            d:
            elem d.type [
              "trackpad"
              "touch"
              "tablet"
            ]
          ) hostCfg.inputDevices;

          touchpad = {
            naturalScrolling = true;
            tapping = true;
            clickMethod = "clickfinger";
          };

          mouse = {
            accelProfile = "adaptive";
            accelSpeed = "0.3";
          };
        };

        # Enable graphics tablet support if needed
        wacom.enable = any (d: d.type == "tablet") hostCfg.inputDevices;
      };

      # Configure display managers
      services.xserver.displayManager = mkIf (!hostCfg.displayType.headless) {
        # GDM configuration
        gdm = {
          enable = cfg.displayManager == "gdm";
          inherit (hostCfg.displayType) wayland;
        };

        # SDDM configuration
        sddm = {
          enable = cfg.displayManager == "sddm";
          inherit (hostCfg.displayType) wayland;
        };

        # LightDM configuration
        lightdm = {
          enable = cfg.displayManager == "lightdm";
        };

        # Autologin configuration
        autoLogin = mkIf cfg.autologin.enable {
          enable = true;
          inherit (cfg.autologin) user;
        };

        # Default session based on display server
        defaultSession = mkIf hostCfg.displayType.wayland "plasma-wayland";
      };
    }

    # Headless-specific configuration
    (mkIf hostCfg.displayType.headless {
      services.xserver.enable = false;
      services.xserver.displayManager.gdm.enable = false;
      services.xserver.displayManager.sddm.enable = false;
      services.xserver.displayManager.lightdm.enable = false;
    })

    # Wayland-specific configuration
    (mkIf hostCfg.displayType.wayland {
      # Environment variables for Wayland
      environment.variables = {
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1"; # For Chromium-based applications
        XDG_SESSION_TYPE = "wayland";
        QT_QPA_PLATFORM = "wayland;xcb";
        GDK_BACKEND = "wayland,x11";
        SDL_VIDEODRIVER = "wayland,x11";
      };

      # Enable XDG Portal for better Wayland integration
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-kde
        ];
      };
    })
  ]);
}
