{ stdenv, fetchurl }:

stdenv.mkDerivation rec {

  name = "logstash-input-journald";
  version = "0.1.0";
  sourceRoot = "plugin";
  srcs = [
    (fetchurl {
      url = "https://github.com/logstash-plugins/${name}/archive/v${version}.tar.gz";
      sha256 = null;
      name = "plugin.tar.gz";
     })
    (fetchurl {
      url = "https://github.com/ledbettj/systemd-journal/archive/v1.2.0.tar.gz";
      sha256 = null;
      name = "systemd.tar.gz";
    })
  ];

  dontBuild    = true;
  dontPatchELF = true;
  dontStrip    = true;
  dontPatchShebangs = true;

  buildCommand = ''
    unpackPhase || true
    ls -la
    mkdir -p $out/logstash
    mkdir -p $out/lib
    cp -r logstash-input-journald-0.1.0/lib/* $out
    cp -r systemd-journal-1.2.0/lib/* $out/lib
  '';

}