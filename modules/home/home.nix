{
  flake.nixosModules.home =
    {
      config,
      lib,
      pkgs,
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
                options.files = lib.mkOption {
                  type = lib.types.attrs;
                  default = { };
                  description = ''
                    Attrset describing files in /home/${name}, nodes containing a source attribute will be
                    treated as paths to be linked, paths may resolve anywhere on the system.
                    Any node may contain a mode attribute to setpermissions for itself. 
                  '';
                  example = {
                    ".config" = {
                      hypr."hyprland.conf".source = pkgs.writeText "hyprland.conf" "my hyprland config";
                      foot."foot.ini".source = pkgs.writeText "foot.ini" "my foot config";
                    };
                    ".ssh" = {
                      config.source = pkgs.writeText "ssh-config" "my ssh config"; # write a file named config to ~/.ssh/
                      mode = "0700"; # set permissions at directory level
                    };
                    myFile = {
                      source = ./file.txt;
                      mode = "0650"; # permissions at file level
                    };
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
          let
            recurse =
              acc: tree:
              lib.concatMapAttrs (
                name: value:
                let
                  path = "${acc}/${name}";
                  nodeMode = value.mode or "-";
                  defaults = {
                    inherit (config.users.users.${user}) group;
                    user = userConfig.username;
                    mode = nodeMode;
                  };
                in
                if lib.hasAttr "source" value then
                  {
                    "${path}"."L+" = {
                      argument = toString value.source;
                    }
                    // defaults;
                  }
                else
                  {
                    "${path}".d = defaults;
                  }
                  // recurse path (
                    lib.removeAttrs value [
                      "mode"
                      "source"
                    ]
                  )
              ) tree;
          in
          lib.nameValuePair "home-${userConfig.username}" (
            recurse config.users.users.${user}.home userConfig.files
          )
        ) cfg.users;
      };
    };
}
