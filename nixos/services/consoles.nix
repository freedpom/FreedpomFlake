# Console configuration module for KMS console
# KNOWN ISSUE: enabling kmscon@tty1 causes it to take over ttys,
# possibly due to seat configuration issues

{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.ff.services.consoles;

  baseArgs =
    [
      "--login-program"
      "${pkgs.shadow}/bin/login"
    ]
    ++ lib.optionals (cfg.autologinUser != null) [
      "--autologin"
      cfg.autologinUser
    ];

  gettyCmd = args: "${lib.getExe' pkgs.util-linux "agetty"} ${lib.escapeShellArgs baseArgs} ${args}";

in
{
  # Configuration options for KMS console
  options.ff.services.consoles = {
    # Core options
    enable = lib.mkEnableOption "Enable fancy console setup";

    # User authentication options
    autologinUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Username of the account that will be automatically logged in at the console.
        If unspecified, a login prompt is shown as usual.
      '';
    };

    # TTY configuration
    gettyAt = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tty1" ];
      description = "List of ttys that should use agetty instead of kmscon";
      example = [
        "tty1"
        "tty4"
      ];
    };

  };
  config = lib.mkIf cfg.enable {

    services.kmscon.enable = true;

    systemd.services = lib.mkMerge (
      builtins.map (ttyId: {

        "kmsconvt@${ttyId}".enable = false;

        "getty@${ttyId}" = {
          enable = true;
          wantedBy = [ "default.target" ];
          serviceConfig = {
            ExecStart = [
              "" # override upstream default with an empty ExecStart
              (gettyCmd "--noclear --keep-baud pts/%I 115200,38400,9600 $TERM")
            ];
            Restart = "always";
          };
          environment.TTY = "%I";
          restartIfChanged = false;
          aliases = [ "autovt@${ttyId}.service" ];
        };
      }) cfg.gettyAt
    );
  };
}
