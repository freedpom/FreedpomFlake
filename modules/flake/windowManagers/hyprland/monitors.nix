{
  flake.homeModules.windowManagers =
    {
      lib,
      osConfig,
      config,
      ...
    }:
    {
      wayland.windowManager.hyprland.settings = lib.mkIf config.ff.desktop.hypr.land.enable {
        monitor = lib.mapAttrsToList (
          name: cfg:
          let
            resolution = "${toString cfg.resolution.width}x${toString cfg.resolution.height}@${toString cfg.framerate}";
            inherit (cfg) position;
            scale = toString cfg.scale;

            base = "${name}, ${resolution}, ${position}, ${scale}";

            transform =
              if (cfg ? transform) && (cfg.transform != null) && (cfg.transform != 0) then
                ", transform, ${toString cfg.transform}"
              else
                "";

            mirror = if (cfg ? mirror) && (cfg.mirror != null) then ", mirror, ${cfg.mirror}" else "";

            bitdepth = if (cfg ? colorDepth) && (cfg.colorDepth == 10) then ", bitdepth, 10" else "";

            cm = if (cfg ? cm) && (cfg.cm != null) then ", cm, ${cfg.cm}" else "";

            sdrbrightness =
              if (cfg ? sdrbrightness) && (cfg.sdrbrightness != null) then
                ", sdrbrightness, ${toString cfg.sdrbrightness}"
              else
                "";

            sdrsaturation =
              if (cfg ? sdrsaturation) && (cfg.sdrsaturation != null) then
                ", sdrsaturation, ${toString cfg.sdrsaturation}"
              else
                "";

            vrr = if (cfg ? vrr) && (cfg.vrr != null) then ", vrr, ${toString cfg.vrr}" else "";
          in
          base + transform + mirror + bitdepth + cm + sdrbrightness + sdrsaturation + vrr
        ) osConfig.ff.hardware.displays;

        workspace = lib.concatLists (
          lib.mapAttrsToList (
            name: cfg: map (ws: "${ws}, monitor:${name}") cfg.workspaces
          ) osConfig.ff.hardware.displays
        );
      };
    };
}
