{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.ff.services.kmscon;

in
{
  # Configuration options for KMS console
  options.ff.services.consoles = {
    # Core options
    enable = lib.mkEnableOption "Enable kms console";

    # User authentication options
    autologinUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default autologin user for all consoles";
    };

    # TTY configuration
     kmscon = lib.mkOption {
      type = lib.types.attrsOf (lib.types.subModule {

      })
    };

  };
  config = lib.mkIf cfg.enable {

    services.kmscon.enable = true;

    systemd = lib.mkIf (cfg.disableAt != null) {

      services = lib.mkMerge (
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
        }) cfg.disableAt
      );
    };
  };
}
