{
  flake.nixosModules.default =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.freedpom.services.ntpd;
    in
    {
      # Configuration options for NTP service
      options.freedpom.services.ntpd = {
        enable = lib.mkEnableOption "Whether to enable Network Time Service (ntpd-rs)";
      };

      config = lib.mkIf cfg.enable {
        services = {
          ntp.enable = false;
          chrony.enable = false;
          timesyncd.enable = false;
          ntpd-rs = {
            enable = true;
            useNetworkingTimeServers = false;
            settings = {
              source = [
                {
                  mode = "nts";
                  address = "virginia.time.system76.com";
                  ntp-version = "auto";
                }
                {
                  mode = "nts";
                  address = "oregon.time.system76.com";
                  ntp-version = "auto";
                }
                {
                  mode = "nts";
                  address = "ohio.time.system76.com";
                  ntp-version = "auto";
                }
                {
                  mode = "nts";
                  address = "time.txryan.com";
                  ntp-version = "auto";
                }
              ];
            };
          };
        };
        networking.timeServers = [ ];
      };
    };
}
