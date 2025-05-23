{
  faad2,
  fetchFromGitHub,
  flac,
  lame,
  lib,
  makeWrapper,
  monkeysAudio,
  nixosTests,
  perlPackages,
  sox,
  stdenv,
  wavpack,
  zlib,
  enableUnfreeFirmware ? false,
}:

let
  binPath = lib.makeBinPath (
    [
      lame
      flac
      faad2
      sox
      wavpack
    ]
    ++ (lib.optional stdenv.hostPlatform.isLinux monkeysAudio)
  );
  libPath = lib.makeLibraryPath [
    zlib
    stdenv.cc.cc
  ];
in
perlPackages.buildPerlPackage rec {
  pname = "slimserver";
  version = "9.0.2";

  src = fetchFromGitHub {
    owner = "LMS-Community";
    repo = "slimserver";
    rev = version;
    hash = "sha256-rwaHlNM5KGqvk8SAdinvCGT5+UUAU8I2jiN5Ine/eds=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs =
    with perlPackages;
    [
      AnyEvent
      ArchiveZip
      AsyncUtil
      AudioScan
      CarpAssert
      CarpClan
      CGI
      ClassAccessor
      ClassAccessorChained
      ClassC3
      # ClassC3Componentised # Error: DBIx::Class::Row::throw_exception(): DBIx::Class::Relationship::BelongsTo::belongs_to(): Can't infer join condition for track
      ClassDataInheritable
      ClassInspector
      ClassISA
      ClassMember
      ClassSingleton
      ClassVirtual
      ClassXSAccessor
      CompressRawZlib
      CryptOpenSSLRSA
      DataDump
      DataPage
      DataURIEncode
      DBDSQLite
      DBI
      # DBIxClass # https://github.com/LMS-Community/slimserver/issues/138
      DigestSHA1
      EncodeDetect
      EV
      ExporterLite
      FileBOM
      FileCopyRecursive
      # FileNext # https://github.com/LMS-Community/slimserver/pull/1140
      FileReadBackwards
      FileSlurp
      FileWhich
      HTMLParser
      HTTPCookies
      HTTPDaemon
      HTTPMessage
      ImageScale
      IOAIO
      IOInterface
      IOSocketSSL
      IOString
      JSONXS
      JSONXSVersionOneAndTwo
      # LogLog4perl # Internal error: Root Logger not initialized.
      LWP
      LWPProtocolHttps
      MP3CutGapless
      NetHTTP
      NetHTTPSNB
      PathClass
      ProcBackground
      # SQLAbstract # DBI Exception: DBD::SQLite::db prepare_cached failed: no such function: ARRAY
      SQLAbstractLimit
      SubName
      TemplateToolkit
      TextUnidecode
      TieCacheLRU
      TieCacheLRUExpires
      TieRegexpHash
      TimeDate
      URI
      URIFind
      UUIDTiny
      XMLParser
      XMLSimple
      YAMLLibYAML
    ]
    # ++ (lib.optional stdenv.hostPlatform.isDarwin perlPackages.MacFSEvents)
    ++ (lib.optional stdenv.hostPlatform.isLinux perlPackages.LinuxInotify2);

  prePatch = ''
    # remove vendored binaries
    rm -rf Bin

    # remove most vendored modules, keeping necessary ones
    mkdir -p CPAN_used/Class/C3/ CPAN_used/SQL/ CPAN_used/File/
    rm -r CPAN/SQL/Abstract/Limit.pm
    cp -rv CPAN/Class/C3/Componentised.pm CPAN_used/Class/C3/
    cp -rv CPAN/DBIx CPAN_used/
    cp -rv CPAN/File/Next.pm CPAN_used/File/
    cp -rv CPAN/Log CPAN_used/
    cp -rv CPAN/SQL/* CPAN_used/SQL/
    rm -r CPAN
    mv CPAN_used CPAN

    # another set of vendored/modified modules exist in lib, more selectively cleaned for now
    rm -rf lib/Audio

    ${lib.optionalString (!enableUnfreeFirmware) ''
      # remove unfree firmware
      rm -rf Firmware
    ''}

    touch Makefile.PL
  '';

  doCheck = false;

  installPhase = ''
    cp -r . $out
    wrapProgram $out/slimserver.pl --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
    chmod +x $out/scanner.pl
    wrapProgram $out/scanner.pl --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
    mkdir $out/bin
    ln -s $out/slimserver.pl $out/bin/slimserver
  '';

  outputs = [ "out" ];

  passthru = {
    tests = {
      inherit (nixosTests) slimserver;
    };

    updateScript = ./update.nu;
  };

  meta = with lib; {
    homepage = "https://lyrion.org/";
    changelog = "https://lyrion.org/getting-started/changelog-lms${lib.versions.major version}";
    description = "Lyrion Music Server (formerly Logitech Media Server) is open-source server software which controls a wide range of Squeezebox audio players";
    # the firmware is not under a free license, so we do not include firmware in the default package
    # https://github.com/LMS-Community/slimserver/blob/public/8.3/License.txt
    license = if enableUnfreeFirmware then licenses.unfree else licenses.gpl2Only;
    mainProgram = "slimserver";
    maintainers = with maintainers; [
      adamcstephens
      jecaro
    ];
    platforms = platforms.unix;
    broken = stdenv.hostPlatform.isDarwin;
  };
}
