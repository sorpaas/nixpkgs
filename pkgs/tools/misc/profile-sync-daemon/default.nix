{ stdenv, fetchgit, rsync, glibc, gawk }:

stdenv.mkDerivation rec {
  version = "git-20170407";
  name = "profile-sync-daemon-${version}";

  src = fetchgit {
    url = "http://github.com/sorpaas/profile-sync-daemon";
    sha256 = "0l9l0s4wpfiqjl6as8akgb75rgxj1b3q6mqwvcq0bgdxrwhv6nx5";
  };

  installPhase = "PREFIX=\"\" DESTDIR=$out make install";

  preferLocalBuild = true;

  meta = with stdenv.lib; {
    description = "Syncs browser profile dirs to RAM";
    longDescription = ''
      Profile-sync-daemon (psd) is a tiny pseudo-daemon designed to manage your
      browser's profile in tmpfs and to periodically sync it back to your
      physical disc (HDD/SSD). This is accomplished via a symlinking step and
      an innovative use of rsync to maintain back-up and synchronization
      between the two. One of the major design goals of psd is a completely
      transparent user experience.
    '';
    homepage = https://github.com/graysky2/profile-sync-daemon;
    downloadPage = https://github.com/graysky2/profile-sync-daemon/releases;
    license = licenses.mit;
    maintainers = [ maintainers.prikhi ];
    platforms = platforms.linux;
  };
}
