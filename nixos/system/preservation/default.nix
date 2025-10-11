{
  config,
  inputs,
  lib,
  ...
}: {
  # user options are in ../userConfig.nix
  options.ff = {
    system.preservation = {
      enable = lib.mkEnableOption "Enable preservation";

      preserveHome = lib.mkEnableOption "Preserve user directories on an ephemeral /home";

      storageDir = lib.mkOption {
        type = lib.types.str;
        default = "/nix/persist";
        description = "Directory where persistent data will be stored";
      };

      directories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra directories to be preserved";
      };

      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra files to be preserved";
      };

      build-dir = lib.mkOption {
        type = lib.types.str;
        default = "/var/tmp/nix";
        description = ''
          The default nix build directory /tmp will often fill the root tmpfs on large builds.
          Changing this to a directory on a physical drive e.g. /var/tmp will fix this but may be undesirable
          on systems that actually have enough memory to build in ram.
        '';
      };
    };
  };

  config.assertions = [
    {
      assertion = config.ff.system.preservation.enable -> (inputs ? preservation);
      message = "Preservation is required as a flake input to enable our preservation helper, please add it.";
    }
  ];

  # Only import config if preservation inputs
  imports = lib.optionals (inputs ? preservation) [./preservation.nix];
}
