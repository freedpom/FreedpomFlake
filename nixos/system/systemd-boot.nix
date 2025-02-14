{
  lib,
  config,
  ...
}:
let
  cfg = config.cm.nixos.system.systemd-boot;
in
{
  options.cm.nixos.system.systemd-boot = {
    enable = lib.mkEnableOption "Enable configuration for boot optimization and systemd-boot setup";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
        #logo = "";managed by stylix
        # theme = "hexagon_2";
        #themePackages = with pkgs; [
        # By default we would install all themes
        #(adi1090x-plymouth-themes.override {
        #selected_themes = [ "hexagon_2" ];
        #})
        #];
      };
      loader = {
        timeout = 0;
        systemd-boot = {
          editor = false;
          enable = true;
          configurationLimit = lib.mkDefault 10;
        };
        efi.canTouchEfiVariables = true;
      };
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "vga=current"
      ];
      consoleLogLevel = lib.mkForce 0;
      initrd = {
        verbose = false;
        systemd.enable = true;
      };
    };
    services.scx.enable = true; # by default uses scx_rustland scheduler
  };
}
