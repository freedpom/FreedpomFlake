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
          accept-flake-config = true;
          connect-timeout = 5;
          min-free = 128000000;
          max-free = 1000000000;
          experimental-features = 'nix-command flakes';
          allowed-users = [ "@wheel" ];
          trusted-users = [ "@wheel" ];
          fallback = true;
          warn-dirty = false;
          auto-optimise-store = true;
          flake-registry = "";
          # Use available binary caches
          builders-use-substitutes = true;
          max-jobs = "auto";
        };
        channel.enable = false;

        registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

        # https://gitlab.com/garuda-linux/garuda-nix-subsystem/-/blob/stable/internal/modules/base/nix.nix?ref_type=heads#L15
        # Make builds run with low priority
        daemonCPUSchedPolicy = "idle";
        daemonIOSchedClass = "idle";
      };
    programs.nh = {
      clean = {
        enable = true;
        extraArgs = "--keep-since 3d --keep 2";
        dates = "daily";
      };
      enable = true;
    };
  };
}
