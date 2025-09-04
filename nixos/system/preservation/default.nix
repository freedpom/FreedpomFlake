{
  config,
  inputs,
  lib,
  ...
}: {
  options.ff = {
    system.preservation = {
      enable = lib.mkEnableOption "Enable preservation";

      preserveHome = lib.mkEnableOption "Preserve user directories on an ephemeral /home";

      storageDir = lib.mkOption {
        type = lib.types.str;
        default = "/nix/persist";
        description = "Directory where persistent data will be stored";
      };

      extraDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra directories to be preserved";
      };

      extraFiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra files to be preserved";
      };
    };

    userConfig.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.preservation = {
            directories = lib.mkOption {
              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
              description = "Extra directories for preservation module";
              default = [];
            };

            files = lib.mkOption {
              type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
              description = "Extra files for preservation module";
              default = [];
            };

            mountOptions = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Mount options for user directories";
              default = [];
            };
          };
        }
      );
    };
  };

  config.assertions = [
    {
      assertion = config.ff.system.preservation.enable -> (inputs ? preservation);
      message = "Preservation module is required to enable preservation, please install it and try again.";
    }
  ];

  # Only import config if preservation inputs, lib.mkIf still evaluates disabled modules and builtin.tryEval would
  # also catch errors from the user defined preservation config, pretty undesirable so this seems like the best option.
  # Importing based on config would cause circular dependencies so we use inputs, can handle error conditions with asserts.
  imports = lib.optionals (inputs ? preservation) [./preservation.nix];
}
