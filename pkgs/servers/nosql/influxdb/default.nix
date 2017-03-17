{ lib, buildGoPackage, fetchFromGitHub, }:

buildGoPackage rec {
  name = "influxdb-${version}";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "influxdata";
    repo = "influxdb";
    rev = "v${version}";
    sha256 = "05ghsb8mplvzvcw72nw9w3gqp900p7pxwzdj8ni400fhagibyj59";
  };

  goPackagePath = "github.com/influxdata/influxdb";

  excludedPackages = "test";

  # Generated with the nix2go
  goDeps = ./. + builtins.toPath "/deps-${version}.nix";

  meta = with lib; {
    description = "An open-source distributed time series database";
    license = licenses.mit;
    homepage = https://influxdb.com/;
    maintainers = with maintainers; [ offline zimbatm ];
    platforms = platforms.linux;
  };
}
