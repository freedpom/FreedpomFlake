let
  # List of users with temporary home directories
  enabledUsers = [
    "codman"
    "quinno"
  ];

  mkUserTmpfs = user: {
    "/home/${user}" = {
      fsType = "tmpfs";
      mountOptions = [
        "mode=755"
        "size=1G"
      ];
    };
  };

  userTmpfsConfigs = builtins.foldl' (acc: user: acc // mkUserTmpfs user) {} enabledUsers;
in {
  # Temporary filesystem configurations
  disko.devices.nodev =
    {
      "/home" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=755"
          "size=256M"
        ];
      };
    }
    // userTmpfsConfigs;
}
