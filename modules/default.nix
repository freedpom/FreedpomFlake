{ lib, ... }:
{
  # Import all files in this directory and subdirectories
  # Ignores paths that contain an "_" at any level

  imports = lib.filter (n: (!lib.hasInfix "_" (builtins.toString n) && (n != ./. + "/default.nix"))) (
    lib.filesystem.listFilesRecursive ./.
  );
}
