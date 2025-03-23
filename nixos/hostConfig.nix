{
  lib,
  ...
}:
{
  options.ff.hostConf = {
    displayType = {
      # headless = lib.mkEnableOption;
      # wayland = lib.mkEnableOption;
      kmscon = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = "";
        description = "list of ttys that will be enabled with kms console";
      };
    };
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
}
