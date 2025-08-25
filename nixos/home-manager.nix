{inputs, ...}: {
  # Home Manager Settings
  home-manager = {
    backupFileExtension = "bk";
    extraSpecialArgs = {
      inherit inputs;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
