{ lib, config, pkgs, ... }: let

cfg = config.ff.hostConf;

kmsConfDir = pkgs.writeTextFile {
  name = "kmscon-config";
  destination = "/kmscon.conf";
  text = cfg.extraConfig;
};

in
{
  options.ff.hostConf = {
    displayType = {
      # headless = lib.mkEnableOption;
      # wayland = lib.mkEnableOption;
      kmscon = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = "";
        description = "list of ttys that will be enabled with kms console";
      };
    };
  };
  tags = lib.mkOption {
    type = lib.types.listOf lib.types.enum [
      "power-save" # Laptops & small arm devices
      "gaming" # High performance gaming
      "rt-audio" # Real-time audio
    ];
    default = "";
    example = "gaming rt-audio";
    description = "";
  };
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
    description = "Configure the system UI for input devices such as a keyboard, mouse, touch screen, trackpad, or controller.";
  };

  config = lib.mkIf cfg.kmscon {
    systemd.services.kmscon = {
      after = [
        "systemd-logind.service"
        "systemd-vconsole-setup.service"
      ];
      requires = [ "systemd-logind.service" ];

      serviceConfig.ExecStart = [
        ""
        ''
          ${pkgs.kmscon}/bin/kmscon "--vt=%I" ${cfg.extraOptions} --seats=seat0 --no-switchvt --configdir ${kmsConfDir} --login -- ${pkgs.shadow}/bin/login -p codman
        ''
      ];

      restartIfChanged = false;
      aliases = [ "autovt@.service" ];
    };

    systemd.suppressedSystemUnits = [ "autovt@.service" ];

    systemd.services.systemd-vconsole-setup.enable = false;
    systemd.services.reload-systemd-vconsole-setup.enable = false;
  };
}
