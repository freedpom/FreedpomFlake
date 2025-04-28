let
  # List of users with home directories
  enabledUsers = [
    "codman"
    "quinno"
  ];

  # Function to generate user subvolumes
  mkUserSubvolume = user: {
    "/nix/home/${user}" = {
      mountpoint = "/nix/home/${user}";
      mountOptions = [
        "commit=60"
        "compress=zstd:5"
        "noatime"
      ];
    };
  };

  # Combine all user subvolumes into one attribute set
  userSubvolumes = builtins.foldl' (acc: user: acc // mkUserSubvolume user) { } enabledUsers;
in
{
  # Home disk configuration
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
                    "commit=60"
                    "compress=zstd:5"
                    "noatime"
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
