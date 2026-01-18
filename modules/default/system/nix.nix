{
  flake.nixosModules.default =
    {
      inputs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.system.nix;
    in
    {
      options.freedpom.system.nix = {
        enable = lib.mkEnableOption "Enable nix system configuration";
      };

      config = lib.mkIf cfg.enable {
        nix =
          let
            flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
          in
          {
            settings = {
              # Core features and permissions
              allowed-users = [ "@wheel" ];
              experimental-features = "nix-command flakes";
              trusted-users = [ "@wheel" ];

              # Behavioral settings
              accept-flake-config = true;
              auto-optimise-store = true;
              fallback = true;
              flake-registry = "";
              warn-dirty = false;

              # Performance settings
              connect-timeout = 5;
              max-free = 1000000000;
              max-jobs = "auto";
              min-free = 128000000;

              # Builder settings
              # Use available binary caches
              builders-use-substitutes = true;
            };
            channel.enable = false;

            # Daemon resource management
            # https://gitlab.com/garuda-linux/garuda-nix-subsystem/-/blob/stable/internal/modules/base/nix.nix?ref_type=heads#L15
            # Make builds run with low priority
            daemonCPUSchedPolicy = "idle";
            daemonIOSchedClass = "idle";

            # Flake registry and nix path
            nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
            registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
          };
        programs.nh = {
          clean = {
            dates = "daily";
            enable = true;
            extraArgs = "--keep-since 3d --keep 2";
          };
          enable = true;
        };
      };
    };
}