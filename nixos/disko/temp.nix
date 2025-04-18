let
  enabledUsers = [
    "quinno"
    "codman"
  ];

  mkUserTmpfs = user: {
    "/home/${user}" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=1G"
        "mode=755"
      ];
    };
  };

  userTmpfsConfigs = builtins.foldl' (acc: user: acc // mkUserTmpfs user) { } enabledUsers;
in
{
  disko.devices.nodev = {
    "/home" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=256M"
        "mode=755"
      ];
    };
  } // userTmpfsConfigs;
}
