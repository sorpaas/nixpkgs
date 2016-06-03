{ nixpkgs ? { outPath = (import ./all-packages.nix {}).lib.cleanSource ../..; revCount = 1234; shortRev = "abcdef"; }
, supportedSystems ? [ "x86_64-linux" ]
, packageSet ? (import ./../..)
, allowTexliveBuilds ? false
, scrubJobs ? true
}:

with import ../../lib;

with rec {

  # Ensure that we don't build packages marked as unfree.
  allPackages = args: packageSet (args // {
    config.allowUnfree = true;
    config.allowTexliveBuilds = allowTexliveBuilds;
    config.inHydra = true;
  });

  pkgs = pkgsFor "x86_64-linux";

  hydraJob' = if scrubJobs then hydraJob else id;

  /* !!! Hack: poor man's memoisation function.  Necessary to prevent
     Nixpkgs from being evaluated again and again for every
     job/platform pair. */
  pkgsFor = system:
    if system == "x86_64-linux" then pkgs_x86_64_linux
    else if system == "i686-linux" then pkgs_i686_linux
    else if system == "x86_64-darwin" then pkgs_x86_64_darwin
    else if system == "x86_64-freebsd" then pkgs_x86_64_freebsd
    else if system == "i686-freebsd" then pkgs_i686_freebsd
    else if system == "i686-cygwin" then pkgs_i686_cygwin
    else if system == "x86_64-cygwin" then pkgs_x86_64_cygwin
    else abort "unsupported system type: ${system}";

  pkgs_x86_64_linux = allPackages { system = "x86_64-linux"; };
  pkgs_i686_linux = allPackages { system = "i686-linux"; };
  pkgs_x86_64_darwin = allPackages { system = "x86_64-darwin"; };
  pkgs_x86_64_freebsd = allPackages { system = "x86_64-freebsd"; };
  pkgs_i686_freebsd = allPackages { system = "i686-freebsd"; };
  pkgs_i686_cygwin = allPackages { system = "i686-cygwin"; };
  pkgs_x86_64_cygwin = allPackages { system = "x86_64-cygwin"; };


  /* The working or failing mails for cross builds will be sent only to
     the following maintainers, as most package maintainers will not be
     interested in the result of cross building a package. */
  crossMaintainers = [ ];


  /* Build a package on the given set of platforms.  The function `f'
     is called for each supported platform with Nixpkgs for that
     platform as an argument .  We return an attribute set containing
     a derivation for each supported platform, i.e. ‘{ x86_64-linux =
     f pkgs_x86_64_linux; i686-linux = f pkgs_i686_linux; ... }’. */
  testOn = systems: f: genAttrs
    (filter (x: elem x supportedSystems) systems) (system: hydraJob' (f (pkgsFor system)));


  /* Similar to the testOn function, but with an additional
     'crossSystem' parameter for allPackages, defining the target
     platform for cross builds. */
  testOnCross = crossSystem: systems: f: {system ? builtins.currentSystem}:
    if elem system systems
    then f (allPackages { inherit system crossSystem; })
    else {};


  /* Given a nested set where the leaf nodes are lists of platforms,
     map each leaf node to `testOn [platforms...] (pkgs:
     pkgs.<attrPath>)'. */
  mapTestOn = mapAttrsRecursive
    (path: systems: testOn systems (pkgs: getAttrFromPath path pkgs));


  /* Similar to the testOn function, but with an additional 'crossSystem'
   * parameter for allPackages, defining the target platform for cross builds,
   * and triggering the build of the host derivation (cross built - crossDrv). */
  mapTestOnCross = crossSystem: mapAttrsRecursive
    (path: systems: testOnCross crossSystem systems
      (pkgs: addMetaAttrs { maintainers = crossMaintainers; } (getAttrFromPath path pkgs)));


  /* Recursively map a (nested) set of derivations to an isomorphic
     set of meta.platforms values. */
  packagePlatforms = mapAttrs (name: value:
    let res = builtins.tryEval (
      if isDerivation value then
        value.meta.hydraPlatforms or (value.meta.platforms or [])
      else if value.recurseForDerivations or false || value.recurseForRelease or false then
        packagePlatforms value
      else
        []);
    in if res.success then res.value else []
    );


  /* Common platform groups on which to test packages. */
  inherit (platforms) unix linux darwin cygwin allBut all mesaPlatforms;

  /* Platform groups for specific kinds of applications. */
  x11Supported = linux;
  gtkSupported = linux;
  ghcSupported = linux;

};

{

  tarball = import ./make-tarball.nix {
    inherit nixpkgs;
    officialRelease = false;
  };

} // (mapTestOn (rec {

  aspell = linux;
  at = linux;
  atlas = linux;
  autoconf = linux;
  automake = linux;
  avahi = linux;
  bash = linux;
  bashInteractive = linux;
  bc = linux;
  binutils = linux;
  bind = linux;
  bumblebee = linux;
  bsdiff = linux;
  bzip2 = linux;
  cmake = linux;
  coreutils = linux;
  cpio = linux;
  cron = linux;
  cups = linux;
  dhcp = linux;
  diffutils = linux;
  e2fsprogs = linux;
  emacs24 = gtkSupported;
  enscript = linux;
  file = linux;
  findutils = linux;
  flex = linux;
  gcc = linux;
  gcj = linux;
  glibc = linux;
  glibcLocales = linux;
  gnugrep = linux;
  gnum4 = linux;
  gnumake = linux;
  gnupatch = linux;
  gnupg = linux;
  gnuplot = linux;
  gnused = linux;
  gnutar = linux;
  gnutls = linux;
  gogoclient = linux;
  grub = linux;
  grub2 = linux;
  gsl = linux;
  guile = linux;  # tests fail on Cygwin
  gzip = linux;
  hddtemp = linux;
  hdparm = linux;
  hello = linux;
  host = linux;
  iana_etc = linux;
  icewm = linux;
  idutils = linux;
  inetutils = linux;
  iputils = linux;
  jnettop = linux;
  jwhois = linux;
  kbd = linux;
  keen4 = ["i686-linux"];
  kvm = linux;
  qemu = linux;
  qemu_kvm = linux;
  less = linux;
  lftp = linux;
  liblapack = linux;
  libtool = linux;
  libtool_2 = linux;
  libxml2 = linux;
  libxslt = linux;
  lout = linux;
  lsof = linux;
  ltrace = linux;
  lvm2 = linux;
  lynx = linux;
  lzma = linux;
  man = linux;
  man-pages = linux;
  mc = linux;
  mcabber = linux;
  mcron = linux;
  mdadm = linux;
  mesa = mesaPlatforms;
  midori = linux;
  mingetty = linux;
  mk = linux;
  mktemp = linux;
  mono = linux;
  monotone = linux;
  mpg321 = linux;
  mutt = linux;
  mysql = linux;
  ncat = linux;
  netcat = linux;
  nfs-utils = linux;
  nix = linux;
  nixUnstable = linux;
  nss_ldap = linux;
  nssmdns = linux;
  ntfs3g = linux;
  ntp = linux;
  openssh = linux;
  openssl = linux;
  pan = gtkSupported;
  par2cmdline = linux;
  pciutils = linux;
  pdf2xml = linux;
  perl = linux;
  pkgconfig = linux;
  pmccabe = linux;
  portmap = linux;
  procps = linux;
  python = linux;
  pythonFull = linux;
  readline = linux;
  rlwrap = linux;
  rpm = linux;
  rsync = linux;
  screen = linux;
  scrot = linux;
  sdparm = linux;
  sharutils = linux;
  sloccount = linux;
  smartmontools = linux;
  sqlite = linux;
  squid = linux;
  ssmtp = linux;
  stdenv = linux;
  strace = linux;
  su = linux;
  sudo = linux;
  sysklogd = linux;
  syslinux = ["i686-linux"];
  sysvinit = linux;
  sysvtools = linux;
  tcl = linux;
  tcpdump = linux;
  texinfo = linux;
  time = linux;
  tinycc = linux;
  unrar = linux;
  unzip = linux;
  upstart = linux;
  usbutils = linux;
  utillinux = linux;
  utillinuxMinimal = linux;
  w3m = linux;
  webkit = linux;
  wget = linux;
  which = linux;
  wicd = linux;
  wireshark = linux;
  wirelesstools = linux;
  wpa_supplicant = linux;
  xfsprogs = linux;
  xkeyboard_config = linux;
  zile = linux;
  zip = linux;
} ))
