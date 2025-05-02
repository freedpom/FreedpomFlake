{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.ff.desktop;
  hostCfg = config.ff.hostConf;
  displayCfg = config.ff.hardware.displays;

  # Helper function to determine if a specific tag is present
  hasTag = tag: elem tag hostCfg.tags;

  # Determine performance profile based on tags and explicit configuration
  effectivePerformanceProfile =
    if hasTag "gaming" || hasTag "rt-audio" then
      "performance"
    else if hasTag "power-save" then
      "power-saver"
    else if hasTag "server" then
      "balanced"
    else
      hostCfg.performanceProfile;

  # Find the primary display if set, otherwise use the first one
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

  # Get all enabled displays
  enabledDisplays = filter (d: d.enabled) displayCfg;

  # Helper to build xrandr script for X11 display setup
  buildXrandrScript =
    displays:
    let
      # Function to generate xrandr command for a single display
      displayToXrandr =
        display:
        let
          port = if display.port != null then display.port else "";
          mode =
            if display.mode != null then
              display.mode
            else if display.resWidth != null && display.resHeight != null && display.refreshRate != null then
              "${toString display.resWidth}x${toString display.resHeight}_${toString display.refreshRate}"
            else
              "";
          position =
            if display.position != null then
              "--pos ${toString display.position.x}x${toString display.position.y}"
            else
              "";
          primary = if display.isPrimary then "--primary" else "";
          rotation = if display.rotation != "normal" then "--rotate ${display.rotation}" else "";
          scale =
            if display.scale != 1.0 then "--scale ${toString display.scale}x${toString display.scale}" else "";
        in
        "${pkgs.xorg.xrandr}/bin/xrandr --output ${port} --mode ${mode} ${position} ${primary} ${rotation} ${scale}";
    in
    pkgs.writeShellScriptBin "configure-displays" (
      concatStringsSep "\n" (map displayToXrandr displays)
    );

in
{
  options.ff.desktop = {
    enable = mkEnableOption "FreedpomFlake desktop environment integration";

    defaultSession = mkOption {
      type = types.str;
      default = if hostCfg.displayType.wayland then "plasma" else "plasma-x11";
      description = "Default desktop session";
      example = "gnome";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base configuration for all desktop systems
    {
      # Apply display server settings based on hostConf
      services.xserver.enable =
        hostCfg.displayType.x11 || (!hostCfg.displayType.wayland && !hostCfg.displayType.headless);

      # Configure KMS console if needed
      ff.services.kmscon = {
        enable = hostCfg.displayType.kmscon != [ ];
        disableAt =
          if hostCfg.displayType.kmscon != [ ] then
            map (tty: "tty${toString tty}") hostCfg.displayType.kmscon
          else
            null;
      };

      # Common input settings
      services.xserver.libinput.enable = any (
        d:
        elem d.type [
          "trackpad"
          "touch"
          "tablet"
        ]
      ) hostCfg.inputDevices;

      # Performance profile settings
      powerManagement = {
        cpuFreqGovernor =
          if effectivePerformanceProfile == "performance" then
            "performance"
          else if effectivePerformanceProfile == "power-saver" then
            "powersave"
          else
            "ondemand"; # balanced
      };

      # For low-latency profile or rt-audio tag
      security.rtkit.enable = effectivePerformanceProfile == "low-latency" || hasTag "rt-audio";

      # Auto-enable services based on tags
      services.thermald.enable = !hostCfg.displayType.headless && hasTag "power-save";
      services.tlp.enable = hasTag "power-save";

      # Bluetooth support if not headless
      hardware.bluetooth.enable = !hostCfg.displayType.headless;

      # Always enable common graphics drivers unless headless
      hardware.opengl = mkIf (!hostCfg.displayType.headless) {
        enable = true;
        driSupport = true;
        driSupport32Bit = hasTag "gaming";
      };
    }

    # X11-specific configuration
    (mkIf hostCfg.displayType.x11 {
      # Configure X11 displays
      services.xserver.displayManager.setupCommands =
        if enabledDisplays != [ ] then "${lib.getExe (buildXrandrScript enabledDisplays)}" else "";

      services.xserver.deviceSection =
        mkIf (primaryDisplay != null && primaryDisplay.resWidth != null && primaryDisplay.resHeight != null)
          ''
            Option "DPMS" "true"
            Option "PreferredMode" "${toString primaryDisplay.resWidth}x${toString primaryDisplay.resHeight}"
          '';

      # Handle VRR (FreeSync/G-SYNC) settings for X11
      environment.etc."X11/xorg.conf.d/20-amdgpu.conf" = mkIf (any (d: d.enableVRR) enabledDisplays) {
        text = ''
          Section "Device"
            Identifier "AMD"
            Driver "amdgpu"
            Option "VariableRefresh" "true"
          EndSection
        '';
      };

      environment.etc."X11/xorg.conf.d/20-nvidia.conf" = mkIf (any (d: d.enableVRR) enabledDisplays) {
        text = ''
          Section "Device"
            Identifier "nvidia"
            Driver "nvidia"
            Option "AllowVRR" "1" 
          EndSection
        '';
      };

      # Input configuration
      services.xserver.wacom.enable = any (d: d.type == "tablet") hostCfg.inputDevices;
    })

    # Wayland-specific configuration
    (mkIf hostCfg.displayType.wayland {
      # Enable Wayland-compatible login managers
      services.xserver.displayManager.gdm = {
        enable = cfg.defaultSession == "gnome";
        wayland = true;
      };

      services.xserver.displayManager.sddm = {
        enable = cfg.defaultSession == "plasma";
        wayland = true;
      };

      # Configure variables for Wayland
      environment.variables = {
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1"; # For Chromium-based applications
        XDG_SESSION_TYPE = "wayland";
        QT_QPA_PLATFORM = "wayland;xcb";
        GDK_BACKEND = "wayland,x11";
        SDL_VIDEODRIVER = "wayland,x11";
      };
    })

    # Gaming profile configuration
    (mkIf (hasTag "gaming") {
      programs.steam.enable = true;
      programs.gamemode.enable = true;
      hardware.xpadneo.enable = true;
      hardware.xone.enable = true; # Xbox One controller support

      # Enable 32-bit graphics drivers for Steam
      hardware.opengl.driSupport32Bit = true;

      # Optimize kernel for gaming
      boot.kernelParams = [
        "intel_pstate=active"
        "mitigations=off"
      ];
    })

    # Development configuration
    (mkIf (hasTag "development") {
      # Enable docker and virtualization tools for development
      virtualisation.docker.enable = true;
      programs.virt-manager.enable = true;
    })

    # Real-time audio configuration
    (mkIf (hasTag "rt-audio") {
      # Optimize for audio production
      boot.kernelPackages = pkgs.linuxPackages_rt;
      security.rtkit.enable = true;
      security.pam.loginLimits = [
        {
          domain = "@audio";
          item = "memlock";
          type = "-";
          value = "unlimited";
        }
        {
          domain = "@audio";
          item = "rtprio";
          type = "-";
          value = "99";
        }
        {
          domain = "@audio";
          item = "nofile";
          type = "soft";
          value = "99999";
        }
        {
          domain = "@audio";
          item = "nofile";
          type = "hard";
          value = "99999";
        }
      ];
    })

    # Kiosk mode configuration
    (mkIf (hasTag "kiosk") {
      # Auto-login for kiosk mode
      services.xserver.displayManager.autoLogin = {
        enable = true;
        user = "kiosk";
      };

      # Disable screen blanking
      services.xserver.serverFlagsSection = ''
        Option "BlankTime" "0"
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime" "0"
      '';
    })
  ]);
}
