{ config, lib, ... }:
let

  cfg = config.ff.system.network;

  ## Port Presets
  pcTCP = [

  ];

  pcUDP = [

  ];

  serverTCP = [

  ];

  serverUDP = [

  ];

  ## Internal stuff, make configuration changes above.
  pcTCPRanges = builtins.filter (lib.strings.hasInfix "-") pcTCP ++ cfg.firewall.extraTCP;
  pcUDPRanges = builtins.filter (lib.strings.hasInfix "-") pcUDP ++ cfg.firewall.extraUDP;
  serverTCPRanges = builtins.filter (lib.strings.hasInfix "-") serverTCP ++ cfg.firewall.extraTCP;
  serverUDPRanges = builtins.filter (lib.strings.hasInfix "-") serverUDP ++ cfg.firewall.extraUDP;
  pcTCPPorts =
    builtins.map lib.toInt (builtins.filter (v: !(lib.strings.hasInfix "-" v)) pcTCP ++ cfg.firewall.extraTCP);
  pcUDPPorts =
    builtins.map lib.toInt (builtins.filter (v: !(lib.strings.hasInfix "-" v)) pcUDP ++ cfg.firewall.extraUDP);
  serverTCPPorts =
    builtins.map lib.toInt (builtins.filter (v: !(lib.strings.hasInfix "-" v)) serverTCP ++ cfg.firewall.extraTCP);
  serverUDPPorts =
    builtins.map lib.toInt (builtins.filter (v: !(lib.strings.hasInfix "-" v)) serverUDP ++ cfg.firewall.extraUDP);

in
{
  options = {
    ff.system.network.firewall = {
      enable = lib.mkEnableOption "Enable Firewall";

      preset = {
        type = lib.types.enum [
          "pc"
          "server"
          "all"
          "most"
        ];
        default = "most";
      };

      extraTCP = {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of TCP ports to be opened, ranges are supported as well.";
      };

      extraUDP = {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of UDP ports to be opened, ranges are supported as well.";
      };
    };
  };
  config.networking = {
    nftables.enable = lib.mkDefault true;

    firewall = {
      enable = lib.mkIf cfg.firewall.enable true;
      allowPing = lib.mkIf (cfg.firewall.preset == "all") true;

      allowedTCPPorts =
        lib.optionals (cfg.firewall.preset == "pc") pcTCPPorts
        ++ lib.optionals (cfg.firewall.preset == "server") serverTCPPorts;

      allowedTCPPortRanges =
        lib.optionals (cfg.firewall.preset == "pc") pcTCPRanges
        ++ lib.optionals (cfg.firewall.preset == "server") serverTCPRanges;

      allowedUDPPorts =
        lib.optionals (cfg.firewall.preset == "pc") pcUDPPorts
        ++ lib.optionals (cfg.firewall.preset == "server") serverUDPPorts;

      allowedUDPPortRanges =
        lib.optionals (cfg.firewall.preset == "pc") pcUDPRanges
        ++ lib.optionals (cfg.firewall.preset == "server") serverUDPRanges;
    };

  };
}
