{ lib, ... }:
{

  options.hostConf = {
    displayType = lib.mkOption {
      type = lib.types.enum [
        "headless"
        "kmscon"
        "wayland"
      ];
      default = "headless";
      example = "wayland";
      description = "Whether to configure the system for a headless server, a KMS console or a Wayland desktop.";
    };
    inputType = lib.mkOption {
      type = lib.types.enum [
        "keyboard"
        "mouse"
        "touch"
        "trackpad"
        "controller"
      ];
      default = "keyboard";
      example = "mouse";
      description = "Whether to configure the system UI for a keyboard, a mouse, a touch screen, trackpad or a controller.";
    };
    persistMain = lib.mkOption {
      type = lib.types.path;
      default = "/nix/persist";
      example = "/nix/persist";
      description = "The directory to store persistent data.";
    };
    persistHome = lib.mkOption {
      type = lib.types.path;
      default = "/nix/persist/home";
      example = "/nix/persist/home";
      description = "The directory to store persistent home data.";
    };
  };
}
