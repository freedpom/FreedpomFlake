{
  perSystem =
    {
      pkgs,
      inputs',
      config,
      ...
    }:
    {
      overlayAttrs = {
        inherit (config.packages) forgecode;
      };
      packages = {
        forgecode =
          let
            inherit (inputs'.fenix.packages.minimal) toolchain;
            version = "1.16.0";
          in
          (pkgs.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          }).buildRustPackage
            {
              pname = "forgecode";
              inherit version;

              src = pkgs.fetchFromGitHub {
                owner = "antinomyhq";
                repo = "forge";
                rev = "v${version}";
                sha256 = "sha256-9vBkb7ut4WWE0npldU7nI5MuABIeJXvfqaDjdS/qv70=";
              };

              nativeBuildInputs = [
                pkgs.pkg-config
                pkgs.protobuf
              ];
              doCheck = false;
              cargoHash = "sha256-wok/WfOn6HtCVrE6K/J/43aqxXzPftQ+RlKQP8HZAgk=";

              meta = with pkgs.lib; {
                description = "A comprehensive coding agent that integrates AI capabilities with your development environment";
                homepage = "https://github.com/antinomyhq/forge";
                license = licenses.asl20;
                platforms = platforms.linux;
              };
            };
      };
    };
  flake.homeModules.core =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.freedpom.default.programs.forgecode;
    in
    {
      options.freedpom.default.programs.forgecode = {
        enable = lib.mkEnableOption "forgecode AI development agent";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.forgecode ];
      };
    };
}
