{
  # Directories that should be preserved if a package matching the key is installed.
  # Uses derivation name so may not exactly match nixpkgs name.

  directories = {
    firefox = ".mozilla";
    gh = ".config/gh";
    legcord = ".config/legcord";
    librewolf = ".librewolf";
    tidal-hifi = ".config/tidal-hifi";
    wivrn = ".config/wivrn";
    steam = ".local/share/Steam";
    stremio-shell = [
      ".stremio-server"
      ".local/share/Smart Code ltd/Stremio"
    ];
  };
  # Same as above but files
  files = {};
}
