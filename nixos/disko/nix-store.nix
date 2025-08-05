_: {
  # Nix store disk configuration
  disko.devices.disk.primary = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "2G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        primarycrypt = {
          size = "100%";
          content = {
            type = "luks";
            name = "nix";
            settings = {
              allowDiscards = true;
            };
            content = {
              type = "btrfs";
              subvolumes = {
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "commit=180"
                    "compress=zstd:10"
                    "noatime"
                  ];
                };
                "/nix/store" = {
                  mountpoint = "/nix/store";
                  mountOptions = [
                    "commit=180"
                    "compress=zstd:5"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/nix".neededForBoot = true;
}
