{ lib, ... }:
{
  imports = lib.map (n: ./${n}) (
    lib.filter (n: n != "default.nix" && !(lib.hasPrefix "_" n)) (lib.attrNames (builtins.readDir ./.))
  );
}
