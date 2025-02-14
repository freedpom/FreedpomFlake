{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.ff.services.pipewire;
in
{

  options.cm.nixos.services.pipewire = {
    enable = lib.mkEnableOption "Enable PipeWire configuration to provide low-latency audio/video routing with pro-audio optimizations";
  };

  config = lib.mkIf cfg.enable {
    # Enable threadirqs for better audio performance
    # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L76
    boot = lib.mkIf config.services.pipewire.enable { kernelParams = [ "threadirqs" ]; };

    environment.systemPackages = with pkgs; [
      pavucontrol
      qpwgraph
      playerctl
      alsa-utils
    ];

    services = {
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = lib.mkForce config.hardware.graphics.enable32Bit;
        };
        pulse.enable = true;
        jack.enable = false;
        wireplumber = {
          enable = true;
        };
      };
      # Expose timers and cpu dma latency the members of the audio group
      # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L139
      udev.extraRules = ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
        DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
      '';
    };
    # Allow members of the "audio" group to set RT priorities
    # https://github.com/musnix/musnix/blob/86ef22cbdd7551ef325bce88143be9f37da64c26/modules/base.nix#L112
    security = {
      pam.loginLimits = [
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
      rtkit.enable = true;
    };
  };

}
