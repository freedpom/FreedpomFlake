{
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
            mountOptions = [ "umask=0077" ];
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
                    "compress=zstd:10"
                    "noatime"
                    "commit=180"
                  ];
                };
                "/nix/store" = {
                  mountpoint = "/nix/store";
                  mountOptions = [
                    "compress=zstd:5"
                    "noatime"
                    "commit=180"
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
