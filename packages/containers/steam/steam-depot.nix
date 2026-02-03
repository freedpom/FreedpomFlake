{ pkgs, lib }:

{
  # https://github.com/nix-community/steam-fetcher/tree/main/fetch-steam
  # Took this lib from fetch-steam because I couldnt get it imported as an input
  steamFetch =
    {
      name,
      debug ? false,
      appId,
      depotId,
      manifestId,
      branch ? null,
      fileList ? [ ],
      hash,
    }:
    let
      fileListFile =
        if fileList != [ ] then
          pkgs.writeText "steam-file-list-${name}.txt" (lib.concatStringsSep "\n" fileList)
        else
          null;

      builder = pkgs.writeShellScript "steam-depot-builder.sh" ''
        #!/bin/bash
        # shellcheck source=/dev/null
        if [ -e .attrs.sh ]; then source .attrs.sh; fi
        source "''${stdenv:?}/setup"

        export HOME
        HOME=$(mktemp -d)

        args=(
          -app "''${appId:?}"
          -depot "''${depotId:?}"
          -manifest "''${manifestId:?}"
        )

        if [ -n "''${branch}" ]; then
          args+=(-beta "''${branch}")
        fi

        if [ -n "''${debug}" ]; then
          args+=(-debug)
        fi

        if [ -n "''${filelist}" ]; then
          args+=(-filelist "''${filelist}")
        fi

        DepotDownloader \
          "''${args[@]}" \
          -dir "''${out:?}"

        rm -rf "''${out:?}/.DepotDownloader"
      '';
    in
    pkgs.stdenvNoCC.mkDerivation {
      name = "${name}-depot";

      inherit
        debug
        appId
        depotId
        manifestId
        branch
        ;

      filelist = fileListFile;
      inherit builder;

      buildInputs = [
        pkgs.depotdownloader
      ];

      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

      outputHash = hash;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    };
}
