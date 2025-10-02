{
  lib,
  osConfig,
  config,
  ...
}: {
  config =
    lib.mkIf
    (
      (config.wayland.windowManager.hyprland.enable or false)
      && (
        lib.length (
          lib.attrNames (lib.mkForce (lib.attrByPath ["ff" "hardware" "displays"] {} osConfig))
        )
        > 0
      )
    )
    {
      wayland.windowManager.hyprland.settings.monitor = lib.mkDefault (
        lib.mapAttrsToList (
          name: cfg: let
            opt = attr: pred: prefix: suffix:
              if (cfg ? ${attr}) && pred cfg.${attr}
              then "${prefix}${toString cfg.${attr}}${suffix}"
              else "";

            resolutionStr = "${toString cfg.resolution.width}x${toString cfg.resolution.height}@${toString cfg.framerate}";
            positionStr = cfg.position;
            scaleStr = toString cfg.scale;

            base = "${name}, ${resolutionStr}, ${positionStr}, ${scaleStr}";

            transformStr = opt "transform" (x: x != null && x != 0) ", transform, " "";
            mirrorStr = opt "mirror" (x: x != null) ", mirror, " "";
            bitdepthStr = opt "colorDepth" (x: x != 24) ", bitdepth, " "";
            colorProfileStr = opt "colorProfile" (x: x != null) ", cm, " "";
            sdrBrightnessStr = opt "sdrBrightness" (x: x != null) ", sdrbrightness, " "";
            sdrSaturationStr = opt "sdrSaturation" (x: x != null) ", sdrsaturation, " "";
            vrrStr = opt "vrr" (x: x != 0) ", vrr, " "";
          in
            base
            + transformStr
            + mirrorStr
            + bitdepthStr
            + colorProfileStr
            + sdrBrightnessStr
            + sdrSaturationStr
            + vrrStr
        ) (lib.mkForce (lib.attrByPath ["ff" "hardware" "displays"] {} osConfig))
      );

      wayland.windowManager.hyprland.settings.workspace = lib.concatLists (
        lib.mapAttrsToList (name: cfg: map (ws: "${ws}, monitor:${name}") cfg.workspaces) (
          lib.mkForce (lib.attrByPath ["ff" "hardware" "displays"] {} osConfig)
        )
      );
    };
}
