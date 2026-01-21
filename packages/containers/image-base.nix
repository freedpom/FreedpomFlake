{
  perSystem =
    { pkgs, ... }:
    {
      _module.args.base = {
        runtimeEnv = pkgs.buildEnv {
          name = "runtime-env";
          paths = [
            pkgs.bashInteractive
            pkgs.coreutils
            pkgs.findutils
            pkgs.gnugrep
            pkgs.gnused
          ];
          pathsToLink = [ "/bin" ];
        };

        systemEnv = pkgs.buildEnv {
          name = "system-env";
          paths = [
            pkgs.cacert
            pkgs.tzdata
          ];
          pathsToLink = [
            "/etc"
            "/share"
          ];
        };
      };
    };
}
