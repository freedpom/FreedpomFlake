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
      description = "Configure the system for a headless server, a KMS console, or a Wayland desktop environment.";
    };
    tags = lib.mkOption {
      type = lib.types.listOf lib.types.enum [
        "power-save" # Laptops & small arm devices
        "gaming" # High performance gaming
        "rt-audio" # Real-time audio
      ];
      default = "";
      example = "gaming rt-audio";
      description = "";
    };
    inputType = lib.mkOption {
      type = lib.types.enum [
        "controller"
        "keyboard"
        "mouse"
        "touch"
        "trackpad"
      ];
      default = "keyboard";
      example = "mouse";
      description = "Configure the system UI for input devices such as a keyboard, mouse, touch screen, trackpad, or controller.";
    };
  };
}
