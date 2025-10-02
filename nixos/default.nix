{lib, ...}: let
  # Read the current directory contents
  dirContents = builtins.readDir ./.;

  # Filter attributes to keep either:
  # - directories that contain a "default.nix" file
  # - files that end with ".nix" but are not "default.nix"
  filteredAttrs =
    lib.attrsets.filterAttrs (
      name: value:
        (value == "directory" && lib.hasAttr "default.nix" (builtins.readDir ./${name}))
        || (lib.hasSuffix ".nix" name && name != "default.nix")
    )
    dirContents;

  # Get the names of the filtered attributes
  attrNames = lib.attrNames filteredAttrs;

  # Map over those names to build import paths
  imports = lib.map (name: ./. + /${name}) attrNames;
in {
  inherit imports;
}
