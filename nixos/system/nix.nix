{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.ff.system.nix;
in
{
  options.ff.system.nix = {
    enable = lib.mkEnableOption "Enable nix system configuration";
  };

  config = lib.mkIf cfg.enable {

    nix =
      let
        flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      in
      {
        settings = {
          connect-timeout = 5;
          min-free = 128000000;
          max-free = 1000000000;
          experimental-features = "nix-command flakes";
          trusted-users = [ "@wheel" ];
          fallback = true;
          warn-dirty = false;
          auto-optimise-store = true;
          flake-registry = "";
        };
        channel.enable = false;

        registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };
  };
}
