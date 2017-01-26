{ fetchurl, buildGoPackage }:

buildGoPackage rec {
  name = "filebeat-${version}";
  goPackagePath = "github.com/elastic/beats";
  version = "5.1.2";
  src = fetchurl {
    url = "https://${goPackagePath}/archive/v${version}.tar.gz";
    sha256 = "1ki37sm6yj7m1ixfsb37128wagfymhh9hz61pc72j0kbpvw59mbw";
  };

  subPackages = [ "filebeat" ];
}
