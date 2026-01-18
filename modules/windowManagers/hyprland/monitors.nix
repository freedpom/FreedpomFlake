{
  flake.homeModules.windowManagers =
    {
      lib,
      osConfig,
      config,
      ...
    }:
    let
      # Change attribute names from displaySpec to monitor descriptions if they exist
      monitors = lib.mapAttrs' (
        name: cfg:
        lib.nameValuePair (
          if cfg.identifiers.description != null then "desc:${cfg.identifiers.description}" else name
        ) cfg
      ) osConfig.freedpom.hardware.displays;
    in
    {
      wayland.windowManager.hyprland.settings = lib.mkIf config.freedpom.windowManagers.hyprland.enable {
        monitor = lib.mapAttrsToList (
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
          base + transform + mirror + bitdepth + cm + sdrbright + sdrsat + vrr
        ) monitors;

        workspace = lib.concatLists (
          lib.mapAttrsToList (name: cfg: map (ws: "${ws}, monitor:${name}") cfg.workspaces) monitors
        );
      };
    };
}
