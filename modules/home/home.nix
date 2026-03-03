{
  flake.nixosModules.home =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.freedpom.system.users;
    in
    {
      options.freedpom.system.users = {
        users = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  files = lib.mkOption {
                    type = lib.types.attrsOf lib.types.package;
                    default = { };
                    description = ''
                      Files to be written to /home/${name} formatted
                      as "path/from/$HOME" = derivation containing file"
                    '';
                  };
                };
              }
            )
          );
        };
      };

      config = {
        systemd.tmpfiles.settings = lib.mapAttrs' (
          user: userConfig:
          lib.nameValuePair "home-${user}" (
            lib.concatMapAttrs (
              path: file:
              let
                parts = lib.init (lib.splitString "/" path);
                parentDirs = lib.imap1 (i: _: lib.concatStringsSep "/" (lib.take i parts)) parts;
              in
              lib.listToAttrs (
                map (
                  dirPath:
                  lib.nameValuePair "/home/${user}/${dirPath}" {
                    d = {
                      inherit (config.users.users.${user}) group;
                      inherit user;
                    };
                  }
                ) parentDirs
              )
              // {
                "/home/${user}/${path}" = {
                  "L+" = {
                    argument = toString file;
                    inherit (config.users.users.${user}) group;
                    inherit user;
                  };
                };
              }
            ) userConfig.files
          )
        ) cfg.users;
      };
    };
}
