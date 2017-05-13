{ lib, buildGoPackage, fetchFromGitHub, }:

buildGoPackage rec {
  name = "influxdb-${version}";
  version = "1.2.4";

  src = fetchFromGitHub {
    owner = "influxdata";
    repo = "influxdb";
    rev = "v${version}";
    sha256 = "05pqsnq8jlc643x3jyil4crmdwgckg6gy5118lxngqvywji35bl1";
  };

  goPackagePath = "github.com/influxdata/influxdb";

  excludedPackages = "test";

  # Generated with the nix2go
  goDeps = ./. + builtins.toPath "/deps.nix";

  meta = with lib; {
    description = "An open-source distributed time series database";
    license = licenses.mit;
    homepage = https://influxdb.com/;
    maintainers = with maintainers; [ offline zimbatm ];
    platforms = platforms.linux;
  };
}
