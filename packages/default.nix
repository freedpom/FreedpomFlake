{
  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    {
      packages = {
        container-hello = inputs'.nix2container.packages.nix2container.buildImage {
          name = "hello";
          config = {
            entrypoint = [ "${pkgs.hello}/bin/hello" ];
          };
        };
      };
    };
}
