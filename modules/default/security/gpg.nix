{
  flake.homeModules.default =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.freedpom.security.gpg;
    in
    {
      options.freedpom.security.gpg = {
        enable = lib.mkEnableOption "GnuPG configuration with security-hardened settings";

        enableSshSupport = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable SSH support for GPG agent";
        };

        defaultCacheTtl = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Default cache TTL for GPG agent in seconds";
        };

        maxCacheTtl = lib.mkOption {
          type = lib.types.int;
          default = 120;
          description = "Maximum cache TTL for GPG agent in seconds";
        };

        pinentryPackage = lib.mkOption {
          type = lib.types.package;
          default = pkgs.pinentry-curses;
          description = "Pinentry package to use for GPG agent";
        };
      };

      config = lib.mkIf cfg.enable {
        services.gpg-agent = {
          enable = true;
          pinentry.package = cfg.pinentryPackage;
          inherit (cfg) defaultCacheTtl;
          defaultCacheTtlSsh = cfg.defaultCacheTtl;
          inherit (cfg) maxCacheTtl;
          maxCacheTtlSsh = cfg.maxCacheTtl;
          inherit (cfg) enableSshSupport;
        };

        programs.gpg = {
          enable = true;
          homedir = "${config.xdg.dataHome}/gnupg";
          mutableKeys = false;
          mutableTrust = false;
          scdaemonSettings = {
            disable-ccid = true;
          };
          settings = {
            personal-cipher-preferences = "AES256 AES192 AES";
            personal-digest-preferences = "SHA512 SHA384 SHA256";
            personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
            default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
            cert-digest-algo = "SHA512";
            s2k-digest-algo = "SHA512";
            s2k-cipher-algo = "AES256";
            charset = "utf-8";
            no-comments = true;
            no-emit-version = true;
            no-greeting = true;
            keyid-format = "0xlong";
            list-options = "show-uid-validity";
            verify-options = "show-uid-validity";
            with-fingerprint = true;
            require-cross-certification = true;
            require-secmem = true;
            no-symkey-cache = true;
            armor = true;
            use-agent = true;
            throw-keyids = true;
          };
        };
      };
    };
}
