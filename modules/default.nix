{ lib, ... }:
let
  # Import all files in this directory.
  # Any path containing an "_" will not be automatically imported.
  # Any path containing a default.nix will only import the default.nix, you will need to take care of imports from there.
  # Files can also be excluded below.

  # Is your module broken? Add it here and forget about it!
  excludedFiles = [ ];

  moduleFiles =
    (
      # Take our two lists as input, get directory of each default.nix and filter files that aren't
      # a default.nix based on their path, if they share a path with a default.nix they are ignored
      v:
      (lib.filter (a: lib.all (b: !lib.path.hasPrefix (dirOf b) a) v.right) v.wrong)
      ++ (map dirOf v.right)
    )
      (
        # Separate our list of all files into files that are a default.nix and files that are not a default.nix
        lib.partition (n: lib.hasSuffix "default.nix" n) (
          # List all files in this directory and its children, remove those whose path contains an "_" at any level
          # Also basic filters to make sure we only import .nix files and don't import this file causing recursion
          lib.filter (
            n: (lib.hasSuffix ".nix" n) && (!lib.hasInfix "_" (toString n)) && (n != ./default.nix)
          ) (lib.filesystem.listFilesRecursive ./.)
        )
      );
in
{
  imports = lib.subtractLists excludedFiles moduleFiles;
}
