{ inputs,  ... }:
{
  flake.packages.x86_64-linux =
    let
      pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      nix2containerPkgs = inputs.nix2container.packages.x86_64-linux;
    in
    {
      containers.hello = nix2containerPkgs.nix2container.buildImage {
        name = "hello";
        config = {
          entrypoint = [ "${pkgs.hello}/bin/hello" ];
        };
      };
    };
}
