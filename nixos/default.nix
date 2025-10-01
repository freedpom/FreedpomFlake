{lib, ...}: let
  getModulePathsFrom = path: let
    dirEntries = builtins.readDir path;

    # Filter for top-level entries
    entries = lib.attrNames dirEntries;

    # Handle folders and nix files
    modulePaths = lib.flatten (
      lib.map (
        name: let
          entryPath = path + "/${name}";
          entryType = dirEntries.${name};
        in
          if entryType == "directory"
          then let
            subDirEntries = builtins.readDir entryPath;
            hasDefault = lib.hasAttr "default.nix" subDirEntries;
            nixFiles = lib.filter (n: lib.hasSuffix ".nix" n && n != "default.nix") (
              lib.attrNames subDirEntries
            );
          in
            if hasDefault
            then [entryPath] # import the whole folder
            else lib.map (file: entryPath + "/${file}") nixFiles # import files only
          else if lib.hasSuffix ".nix" name && name != "default.nix"
          then [entryPath] # top-level .nix file (not default.nix)
          else [] # ignore everything else
      )
      entries
    );
  in
    modulePaths;

  localModules = getModulePathsFrom ./.;
  commonModules = getModulePathsFrom ../common;
in {
  imports = localModules ++ commonModules;
}
