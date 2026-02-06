{ lib
, stdenvNoCC
, pkgs
, depotdownloader
, cacert
}:
# TODO: Multi Depot Download, merge together
let
  fetchSteamDepot =
    lib.makeOverridable (
      lib.extendMkDerivation {
        constructDrv = stdenvNoCC.mkDerivation;

        excludeDrvArgNames = [ "sha256" "hash" ];

        extendDrvArgs =
          finalAttrs:
          lib.fetchers.withNormalizedHash { } (
            {
              name,

              # Core IDs
              appId,
              depotId ? null,
              manifestId ? null,

              # Workshop
              ugcId ? null,
              pubfileId ? null,

              # Optional
              branch ? null,
              branchPassword ? null,
              fileList ? [ ],
              username ? null,
              password ? null,
              rememberPassword ? false,
              os ? null,
              osarch ? null,
              allPlatforms ? false,
              allArchs ? false,
              allLanguages ? false,
              language ? null,
              lowViolence ? false,
              validate ? false,
              manifestOnly ? false,
              cellId ? null,
              maxDownloads ? null,
              useLancache ? false,
              debug ? false,

              preFetch ? "",
              postFetch ? "",

              outputHash ? lib.fakeHash,
              outputHashAlgo ? null,
              nativeBuildInputs ? [ ],
              passthru ? { },
              meta ? { },
            }:

            let
              fileListFile =
                if fileList != [ ] then
                  pkgs.writeText "steam-file-list-${name}.txt" (lib.concatStringsSep "\n" fileList)
                else
                  null;
            in
            {
              __structuredAttrs = true;

              inherit name;

              builder = ./builder.sh;

              nativeBuildInputs = [ depotdownloader cacert ] ++ nativeBuildInputs;

              SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

              env = {
                STEAM_APP_ID = toString appId;
                STEAM_DEPOT_ID = if depotId != null then toString depotId else "";
                STEAM_MANIFEST_ID = if manifestId != null then toString manifestId else "";

                STEAM_UGC_ID = if ugcId != null then toString ugcId else "";
                STEAM_PUBFILE_ID = if pubfileId != null then toString pubfileId else "";

                STEAM_BRANCH = lib.optionalString (branch != null) branch;
                STEAM_BRANCH_PASSWORD = lib.optionalString (branchPassword != null) branchPassword;

                STEAM_USERNAME = lib.optionalString (username != null) username;
                STEAM_PASSWORD = lib.optionalString (password != null) password;

                STEAM_OS = lib.optionalString (os != null) os;
                STEAM_OSARCH = lib.optionalString (osarch != null) osarch;

                STEAM_ALL_PLATFORMS = lib.optionalString allPlatforms "1";
                STEAM_ALL_ARCHS     = lib.optionalString allArchs "1";
                STEAM_ALL_LANGUAGES = lib.optionalString allLanguages "1";
                STEAM_LOWVIOLENCE   = lib.optionalString lowViolence "1";
                STEAM_VALIDATE      = lib.optionalString validate "1";
                STEAM_MANIFEST_ONLY = lib.optionalString manifestOnly "1";
                STEAM_USE_LANCACHE  = lib.optionalString useLancache "1";
                STEAM_DEBUG         = lib.optionalString debug "1";
                STEAM_REMEMBER_PASSWORD = lib.optionalString rememberPassword "1";

                STEAM_FILELIST = if fileListFile != null then fileListFile else "";
                STEAM_CELLID = lib.optionalString (cellId != null) cellId;
                STEAM_MAX_DOWNLOADS = if maxDownloads != null then toString maxDownloads else "";
                STEAM_PREFETCH = preFetch;
                STEAM_POSTFETCH = postFetch;
              };

              # All hash normalization handled by withNormalizedHash
              inherit outputHash outputHashAlgo;
              outputHashMode = "recursive";
              preferLocalBuild = true;

              passthru = passthru // {
                fetchInfo = {
                  type = "steam-depot";
                  inherit appId depotId manifestId branch branchPassword;
                };
              };

              inherit meta;
            }
          );

        inheritFunctionArgs = false;
      }
    );
in
{
  inherit fetchSteamDepot;
}
