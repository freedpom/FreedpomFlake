{
  pkgs ? import <nixpkgs> { },
}:
pkgs.dockerTools.buildImage {
  name = "authentik";
  #fromImage=base-image
  meta.description = "The authentication glue you need.";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ pkgs.authentik ];
    pathsToLink = [ "/bin" ];
  };
}
