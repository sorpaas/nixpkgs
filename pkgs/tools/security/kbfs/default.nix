{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "kbfs-2017-02-09-git";

  goPackagePath = "github.com/keybase/kbfs";
  subPackages = [ "kbfsfuse" ];

  dontRenameImports = true;

  src = fetchFromGitHub {
    owner = "keybase";
    repo = "kbfs";
    rev = "68db99459ff7de01eb762397e7d601afbf1900a3";
    sha256 = "04s59nm3rcbxfls1976hia8q4p96r7bcvmcgkynnmacb4ha05dk1";
  };

  buildFlags = [ "-tags production" ];

  meta = with stdenv.lib; {
    homepage = https://www.keybase.io;
    description = "The Keybase FS FUSE driver";
    platforms = platforms.linux;
    maintainers = with maintainers; [ bennofs ];
  };
}
