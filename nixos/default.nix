{lib, ...}: {
  imports =
    lib.map (n: ./. + /${n}) (
      lib.attrNames (
        lib.attrsets.filterAttrs (
          n: v: (
            ((v == "directory") && (lib.hasAttr "default.nix" (builtins.readDir ./${n})))
            || (lib.hasSuffix ".nix" n) && (n != "default.nix")
          )
        ) (builtins.readDir ./.)
      )
    )
    ++ [../common];
}
