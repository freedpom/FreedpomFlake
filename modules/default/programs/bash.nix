{
  flake.homeModules.default =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.freedpom.programs.bash;
    in
    {
      options.freedpom.programs.bash = {
        enable = lib.mkEnableOption "Bash shell configuration with completion and history management";

        historySize = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = "Number of commands to save in history";
        };

        historyFileSize = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = "Maximum size of history file";
        };

        historyIgnore = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "clear"
            "exit"
          ];
          description = "Commands to ignore in history";
        };
      };

      config = lib.mkIf cfg.enable {
        programs.bash = {
          # Core configurations
          enable = true;
          enableCompletion = true;

          # History settings
          historyControl = [ "ignoreboth" ];
          historyFile = "${config.home.homeDirectory}/.bash_history";
          inherit (cfg) historyFileSize;
          inherit (cfg) historyIgnore;
          inherit (cfg) historySize;
        };
      };
    };
}
