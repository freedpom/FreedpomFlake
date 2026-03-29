{
  flake.modules.hjem.desktop =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.desktop.hyprland;

      toLiteralString = s: if lib.isBool s then lib.boolToString s else toString s;

      splitCfg = {
        attrs = lib.filterAttrs (_: v: lib.isAttrs v) cfg.settings;
        lists = lib.filterAttrs (_: v: lib.isList v) cfg.settings;
      };

      # convert section of attrs into single string
      sectionCfg =
        s: lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "  ${n}=${toLiteralString v}") s);

      # map over attrs from config with sectionCfg, output attrset of strings
      attrCfg = lib.mapAttrs (n: v: "${n} {\n" + (sectionCfg v) + "\n}\n\n") splitCfg.attrs;

      # convert list based config into atrset of strings
      listCfg = lib.mapAttrs (
        n: v: lib.concatStringsSep "\n" ((lib.map (c: "${n}=${c}") v) ++ [ "\n" ])
      ) splitCfg.lists;

      monitorCfg =
        let
          monitors = lib.mapAttrs' (
            name: cfg:
            lib.nameValuePair (
              if cfg.identifiers.description != null then "desc:${cfg.identifiers.description}" else name
            ) cfg
          ) osConfig.freedpom.hardware.displays;
        in
        {
          monitors' =
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: cfg:
                let
                  resolution = "${toString cfg.resolution.width}x${toString cfg.resolution.height}@${toString cfg.framerate}";
                  inherit (cfg) position;
                  scale = toString cfg.scale;

                  base = "${name}, ${resolution}, ${position}, ${scale}";

                  transform = lib.optionalString (cfg.transform != null) ", transform, ${toString cfg.transform}";

                  mirror = lib.optionalString (cfg.mirror != null) ", mirror, ${cfg.mirror}";

                  bitdepth = lib.optionalString (cfg.colorDepth == 10) ", bitdepth, 10";

                  cm = lib.optionalString (cfg.colorProfile != null) ", cm, ${cfg.colorProfile}";

                  sdrbright = lib.optionalString (
                    cfg.sdrBrightness != null
                  ) ", sdrbrightness, ${toString cfg.sdrBrightness}";

                  sdrsat = lib.optionalString (
                    cfg.sdrSaturation != null
                  ) ", sdrsaturation, ${toString cfg.sdrSaturation}";

                  vrr = lib.optionalString (cfg.vrr != null) ", vrr, ${toString cfg.vrr}";
                in
                "monitor=" + base + transform + mirror + bitdepth + cm + sdrbright + sdrsat + vrr
              ) monitors
            )
            + "\n\n";
          workspaces' =
            lib.concatStringsSep "\n" (
              lib.concatLists (
                lib.mapAttrsToList (name: cfg: map (ws: "workspace=${ws}, monitor:${name}") cfg.workspaces) monitors
              )
            )
            + "\n\n";
        };

      cursorCfg =
        lib.optionalAttrs
          (
            (config.freedpom.desktop.cursors.hyprcursor.theme.name != "")
            || (config.freedpom.desktop.cursors.xcursor.theme.name != "")
          )
          {
            cursors =
              lib.optionalString (config.freedpom.desktop.cursors.hyprcursor.theme.name != "") ''
                env=HYPRCURSOR_THEME,${config.freedpom.desktop.cursors.hyprcursor.theme.name}
                env=HYPRCURSOR_SIZE,${config.freedpom.desktop.cursors.hyprcursor.size}
              ''
              + lib.optionalString (config.freedpom.desktop.cursors.xcursor.theme.name != "") ''
                env=XCURSOR_THEME,${config.freedpom.desktop.cursors.xcursor.theme.name}
                env=XCURSOR_SIZE,${config.freedpom.desktop.cursors.xcursor.size}
                exec=dconf write /org/gnome/desktop/interface/cursor-theme "'${config.freedpom.desktop.cursors.xcursor.theme.name}'"
              ''
              + "\n";
          };

      bigCfg = attrCfg // listCfg // monitorCfg // cursorCfg;

      # Values that should be put at the top of the config, in order of priority
      priorityValues = [
        "source"
        "env"
        "cursors"
        "bezier"
      ];

      # Check what priority values actually exist in the config
      priorityValues' = lib.lists.intersectLists priorityValues (lib.attrNames bigCfg);

      # Create final section order from priorityValues and the alphebetized output of attrNames from bigCfg
      order = priorityValues' ++ (lib.lists.subtractLists priorityValues' (lib.attrNames bigCfg));

      finalCfg = lib.foldl' (acc: n: acc + bigCfg.${n}) "" order;
    in
    {
      options.freedpom.desktop.hyprland = {
        enable = lib.mkEnableOption "Enable hyprland config generation";
        autostart = lib.mkEnableOption "Autostart hyprland(assumes UWSM for now)";
        settings = lib.mkOption {
          type = lib.types.anything;
          default = { };
        };
      };
      config = lib.mkIf cfg.enable {
        xdg = {
          config.files."hypr/hyprland.conf".text = finalCfg;
        };
        systemd.services.uwsm-hyprland = {
          description = "Start hyprland session with uwsm";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.bash}/bin/bash -lc 'if uwsm check may-start; then exec uwsm start hyprland-uwsm.desktop; fi'";
            Type = "simple";
          };
        };
      };
    };
}
