{
  pkgs ? import <nixpkgs> { },
}:
pkgs.dockerTools.buildImage {
  name = "postgresql";
  #fromImage=base-image
  tag = "16-alpine";
  meta.description = "Powerful, open source object-relational database system.";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ pkgs.postgresql_16 ];
    pathsToLink = [ "/bin" ];
  };
}
