{
  # Directories that should be preserved if a package matching the key is installed.
  # Matches the derivations pname so check pkgs.<package>.pname for the actual match.

  directories = {
    firefox = ".mozilla";
    gh = ".config/gh";
    legcord = ".config/legcord";
    librewolf = ".librewolf";
    prismlauncher = ".local/share/PrismLauncher";
    tidal-hifi = ".config/tidal-hifi";
    wivrn = ".config/wivrn";
    steam = ".local/share/Steam";
    flatpak = [
      ".var/app"
      ".local/share/flatpak"
    ];
    r2modman = [
      ".config/r2modman"
      ".config/r2modmanPlus-local"
    ];
    stremio-shell = [
      ".stremio-server"
      ".local/share/Smart Code ltd/Stremio"
    ];
  };
  # Same as above but files
  files = { };
}
