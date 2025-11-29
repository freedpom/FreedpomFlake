{
  lib,
  pkgs,
  config,
  ...
}:

let
  gpgAgentConf = pkgs.writeText "gpg-agent.conf" ''
    enable-ssh-support
    ttyname $GPG_TTY
    default-cache-ttl 60
    max-cache-ttl 120
    pinentry-program ${pkgs.pinentry-curses}/bin/pinentry
  '';

  gpgConf = pkgs.writeText "gpg.conf" ''
    personal-cipher-preferences AES256 AES192 AES
    personal-digest-preferences SHA512 SHA384 SHA256
    personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
    default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
    cert-digest-algo SHA512
    s2k-digest-algo SHA512
    s2k-cipher-algo AES256
    charset utf-8
    no-comments
    no-emit-version
    no-greeting
    keyid-format 0xlong
    list-options show-uid-validity
    verify-options show-uid-validity
    with-fingerprint
    require-cross-certification
    require-secmem
    no-symkey-cache
    armor
    use-agent
    throw-keyids
  '';
in
{
  options.ff.cryptography.gnupg = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the cryptography gnupg module.";
    };
  };

  config = lib.mkIf config.ff.cryptography.gnupg.enable {
    programs.gnupg = {
      dirmngr.enable = true;
      agent.enable = true;
      agent.enableSSHSupport = true;
    };

    environment.interactiveShellInit = ''
      if [ -z "$GNUPGHOME" ]; then
        echo "[WARNING] GNUPGHOME not set, defaulting to ~/.gnupg"
        export GNUPGHOME="$HOME/.gnupg"
      fi

      if [ ! -d "$GNUPGHOME" ]; then
        install -d -m 700 "$GNUPGHOME"
      fi

      if [ ! -f "$GNUPGHOME/gpg.conf" ]; then
        cp ${gpgConf} "$GNUPGHOME/gpg.conf"
      fi

      if [ ! -f "$GNUPGHOME/gpg-agent.conf" ]; then
        cp ${gpgAgentConf} "$GNUPGHOME/gpg-agent.conf"
      fi
    '';
  };
}
