let
  enabledUsers = [ "quinno" "codman" ];

  # Function to generate user subvolumes
  mkUserSubvolume = user: {
    "/nix/home/${user}" = {
      mountpoint = "/nix/home/${user}";
      mountOptions = [
        "compress=zstd:5"
        "noatime"
        "commit=60"
      ];
    };
  };

  # Combine all user subvolumes into one attribute set
  userSubvolumes = builtins.foldl' (acc: user: acc // mkUserSubvolume user) {} enabledUsers;
in {
  disko.devices.disk.home = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        homecrypt = {
          size = "100%";
          content = {
            type = "luks";
            name = "home";
            settings = {
              allowDiscards = true;
            };
            content = {
              type = "btrfs";
              subvolumes = {
                "/nix/home" = {
                  mountpoint = "/nix/home";
                  mountOptions = [
                    "compress=zstd:5"
                    "noatime"
                    "commit=60"
                  ];
                };
              } // userSubvolumes;
            };
          };
        };
      };
    };
  };
}
