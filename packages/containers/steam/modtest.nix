{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit ((pkgs.callPackage ../../fetchsteam/fetch-steam.nix { inherit pkgs lib; })) fetchSteamDepot;
    in
    {
      packages = {
        zomboid-mods-test = fetchSteamDepot {
          name = "zomboid-mods-test";
          appId = "108600";
          modlist = [
            "3391928681"
            "3391244620"
            "3391149570"
          ];
          hash = "sha256-6LWYA84RC7ppMVDV8peVfPvFwD15x7Fy9zE3+Xim974=";
        };
      };
    };
}
