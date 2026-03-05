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
                    Attrset describing files in /home/${name}, non leaf nodes will be treated as directories
                    and leaf nodes containing a derivation or path will be treated as files to be linked.
                    Attrs may contain a mode value to set permissions for themselves and their children.
                  '';
                  example = {
                    ".config" = {
                      hypr."hyprland.conf" = pkgs.writeText "hyprland.conf" "my hyprland config";
                      foot."foot.ini" = pkgs.writeText "foot.ini" "my foot config";
                    };
                    ".ssh" = {
                      config = pkgs.writeText "ssh-config" "my ssh config";
                      mode = 0700;
                    };
                    myFile = ./file.txt;
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
              acc: defaultMode: tree:
              lib.concatMapAttrs (
                name: value:
                let
                  path = "${acc}/${name}";
                  nodeMode = value.mode or defaultMode;
                  defaults = {
                    inherit user;
                    inherit (config.users.users.${user}) group;
                    mode = toString nodeMode;
                  };
                in
                if lib.isPath value || lib.isDerivation value then
                  {
                    "${path}"."L+" = defaults // {
                      argument = toString value;
                    };
                  }
                else
                  {
                    "${path}".d = defaults;
                  }
                  // recurse path nodeMode (lib.removeAttrs value [ "mode" ])
              ) tree;
          in
          lib.nameValuePair "home-${user}" (recurse "/home/${user}" "-" userConfig.files)
        ) cfg.users;
      };
    };
}
