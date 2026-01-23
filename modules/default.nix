{ lib, ... }:
let
  # Is your module broken? Add it here and forget about it!
  excludedFiles = [ ];

  # Lists all .nix files in this directory and its children
  # Excludes this file and any files whose path contains an "_" at any level
  moduleFiles = lib.filter (
    n: (lib.hasSuffix ".nix" n) && (!lib.hasInfix "_" (toString n) && (n != ./default.nix))
  ) (lib.filesystem.listFilesRecursive ./.);
in
{

  imports = lib.subtractLists excludedFiles moduleFiles;
}
