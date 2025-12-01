{
  config,
  lib,
  ...
}:
let
  cfg = config.ff.userConfig;

  userNames = lib.attrNames cfg.users;

  standardGroups = [ "networkmanager" ];
  administratorGroups = [ "wheel" ];

  isSystemUser = role: role == "system";
  isAdministrator = role: role == "admin";
  hasBaseTag = tags: lib.elem "base" tags;

  buildUserGroups =
    userConfig:
    userConfig.extraGroups
    ++ lib.optionals (isAdministrator userConfig.role) administratorGroups
    ++ lib.optionals (hasBaseTag userConfig.tags) standardGroups;

  buildUserConfiguration =
    userName:
    let
      userConfig = cfg.users.${userName};
    in
    userConfig.userOptions
    // {
      isSystemUser = isSystemUser userConfig.role;
      isNormalUser = !isSystemUser userConfig.role;
      createHome = !isSystemUser userConfig.role;
      extraGroups = buildUserGroups userConfig;
    };
in
{
  options.ff.userConfig = {
    mutableUsers = lib.mkEnableOption "user modification after system activation" // {
      description = ''
        Whether to allow user accounts to be modified outside of the NixOS configuration.
        When disabled, user changes can only be made through this configuration module.
      '';
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            role = lib.mkOption {
              type = lib.types.enum [
                "user"
                "admin"
                "system"
              ];
              default = "user";
              example = "admin";
              description = ''
                The role determines the user's privileges and account type.
                - user: Standard user account with a home directory
                - admin: Administrative user with wheel group membership
                - system: Service account without a home directory
              '';
            };

            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              example = [
                "base"
                "gaming"
                "development"
              ];
              description = ''
                Arbitrary tags used to classify users and automatically assign group memberships.
                The 'base' tag adds the user to standard groups like networkmanager.
              '';
            };

            userOptions = lib.mkOption {
              type = lib.types.submodule {
                freeformType = lib.types.attrs;
              };
              default = { };
              example = lib.literalExpression ''
                {
                  uid = 1000;
                  description = "Alice Smith";
                  shell = pkgs.zsh;
                  hashedPasswordFile = "/run/secrets/alice-password";
                  linger = true;
                  extraGroups = [ "libvirtd" ];
                  openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
                }
              '';
              description = ''
                Direct passthrough to users.users.<name> options. Any option valid for
                users.users can be specified here. Common options include:
                - uid: User ID number
                - description: Full name or GECOS field
                - shell: Login shell package
                - hashedPassword: Password hash
                - hashedPasswordFile: Path to password hash file
                - linger: Enable systemd user instance persistence
                - openssh.authorizedKeys.keys: SSH public keys
                - openssh.authorizedKeys.keyFiles: Paths to SSH key files
                - openssh.authorizedPrincipals: SSH certificate principals
                See users.users.<name> in NixOS manual for complete list.
              '';
            };

            preservation = {
              directories = lib.mkOption {
                type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                default = [ ];
                example = [
                  ".config/nvim"
                  {
                    directory = ".local/share/Steam";
                    method = "symlink";
                  }
                ];
                description = ''
                  Home directory paths to persist across system rebuilds when using an impermanence setup.
                  Can be strings for simple paths or attribute sets with method and mode options.
                '';
              };

              files = lib.mkOption {
                type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
                default = [ ];
                example = [
                  ".bashrc"
                  {
                    file = ".ssh/id_ed25519";
                    mode = "0600";
                  }
                ];
                description = ''
                  Home directory files to persist across system rebuilds when using an impermanence setup.
                  Can be strings for simple paths or attribute sets with permissions and mode options.
                '';
              };

              mountOptions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [
                  "noatime"
                  "compress=zstd"
                ];
                description = ''
                  Filesystem mount options applied to this user's persistent storage locations.
                  Useful for optimizing performance or enabling filesystem-specific features.
                '';
              };
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          alice = {
            role = "admin";
            tags = [ "base" "development" ];
            userOptions = {
              uid = 1000;
              description = "Alice Smith";
              shell = pkgs.zsh;
              hashedPasswordFile = "/run/secrets/alice-password";
              linger = true;
              extraGroups = [ "libvirtd" ];
              openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
            };
          };
          nginx = {
            role = "system";
            userOptions = {
              uid = 60;
              description = "Nginx web server user";
            };
          };
        }
      '';
      description = ''
        User account definitions. The attribute name becomes the username.
        Each user can be configured with a role, tags for automatic group assignment,
        and any standard users.users options via the userOptions attribute.
      '';
    };
  };

  config = {
    users = {
      inherit (cfg) mutableUsers;
      users = lib.genAttrs userNames buildUserConfiguration;
    };
  };
}
