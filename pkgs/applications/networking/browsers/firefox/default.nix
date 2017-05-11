{ lib, stdenv, fetchurl, pkgconfig, gtk2, pango, perl, python, zip, libIDL
, libjpeg, zlib, dbus, dbus_glib, bzip2, xorg
, freetype, fontconfig, file, alsaLib, nspr, nss, libnotify
, yasm, mesa, sqlite, unzip, makeWrapper
, hunspell, libevent, libstartup_notification, libvpx
, cairo, gstreamer, gst-plugins-base, icu, libpng, jemalloc, libpulseaudio
, autoconf213, which, cargo, rustc, llvm
, writeScript, xidel, common-updater-scripts, coreutils, gnused, gnugrep, curl
, enableGTK3 ? false, gtk3, wrapGAppsHook
, debugBuild ? false
, # If you want the resulting program to call itself "Firefox" instead
  # of "Nightly" or whatever, enable this option.  However, those
  # binaries may not be distributed without permission from the
  # Mozilla Foundation, see
  # http://www.mozilla.org/foundation/trademarks/.
  enableOfficialBranding ? false
}:

assert stdenv.cc ? libc && stdenv.cc.libc != null;

let

common = { pname, version, sha512, updateScript }: stdenv.mkDerivation rec {
  name = "${pname}-unwrapped-${version}";

  src = fetchurl {
    url =
      let ext = if lib.versionAtLeast version "41.0" then "xz" else "bz2";
      in "mirror://mozilla/firefox/releases/${version}/source/firefox-${version}.source.tar.${ext}";
    inherit sha512;
  };

  # this patch should no longer be needed in 53
  # from https://bugzilla.mozilla.org/show_bug.cgi?id=1013882
  patches = lib.optional debugBuild ./fix-debug.patch;

  buildInputs =
    [ gtk2 zip libIDL libjpeg zlib bzip2
      dbus dbus_glib pango freetype fontconfig xorg.libXi
      xorg.libX11 xorg.libXrender xorg.libXft xorg.libXt file
      alsaLib nspr nss libnotify xorg.pixman yasm mesa
      xorg.libXScrnSaver xorg.scrnsaverproto
      xorg.libXext xorg.xextproto sqlite unzip
      hunspell libevent libstartup_notification libvpx /* cairo */
      icu libpng jemalloc llvm
      libpulseaudio # only headers are needed
    ]
    ++ lib.optional enableGTK3 gtk3
    ++ lib.optionals (!passthru.ffmpegSupport) [ gstreamer gst-plugins-base ];

  nativeBuildInputs =
    [ autoconf213 which gnused pkgconfig perl python cargo rustc ]
    ++ lib.optional enableGTK3 wrapGAppsHook;

  configureFlags =
    [ "--enable-application=browser"
      "--with-system-jpeg"
      "--with-system-zlib"
      "--with-system-bz2"
      "--with-system-nspr"
      "--with-system-nss"
      "--with-system-libevent"
      "--with-system-libvpx"
      "--with-system-png" # needs APNG support
      "--with-system-icu"
      "--enable-alsa"
      "--enable-system-ffi"
      "--enable-system-hunspell"
      "--enable-system-pixman"
      "--enable-system-sqlite"
      #"--enable-system-cairo"
      "--enable-startup-notification"
      "--enable-content-sandbox"            # available since 26.0, but not much info available
      "--disable-crashreporter"
      "--disable-tests"
      "--disable-necko-wifi" # maybe we want to enable this at some point
      "--disable-updater"
      "--enable-jemalloc"
      "--disable-gconf"
      "--enable-default-toolkit=cairo-gtk${if enableGTK3 then "3" else "2"}"
      "--with-google-api-keyfile=ga"
    ]
    ++ (if debugBuild then [ "--enable-debug" "--enable-profiling" ]
                      else [ "--disable-debug" "--enable-release"
                             "--enable-optimize"
                             "--enable-strip" ])
    ++ lib.optional enableOfficialBranding "--enable-official-branding";

  enableParallelBuilding = true;

  preConfigure =
    ''
      configureScript="$(realpath ./configure)"
      mkdir ../objdir
      cd ../objdir

      # Google API key used by Chromium and Firefox.
      # Note: These are for NixOS/nixpkgs use ONLY. For your own distribution,
      # please get your own set of keys.
      echo "AIzaSyDGi15Zwl11UNe6Y-5XW_upsfyw31qwZPI" >ga
    '';

  preInstall =
    ''
      # The following is needed for startup cache creation on grsecurity kernels.
      paxmark m ../objdir/dist/bin/xpcshell
    '';

  postInstall =
    ''
      # For grsecurity kernels
      paxmark m $out/lib/firefox-[0-9]*/{firefox,firefox-bin,plugin-container}

      # Remove SDK cruft. FIXME: move to a separate output?
      rm -rf $out/share/idl $out/include $out/lib/firefox-devel-*

      # Needed to find Mozilla runtime
      gappsWrapperArgs+=(--argv0 "$out/bin/.firefox-wrapped")
    '';

  postFixup =
    # Fix notifications. LibXUL uses dlopen for this, unfortunately; see #18712.
    ''
      patchelf --set-rpath "${lib.getLib libnotify
        }/lib:$(patchelf --print-rpath "$out"/lib/firefox-*/libxul.so)" \
          "$out"/lib/firefox-*/libxul.so
    '';

  doInstallCheck = true;
  installCheckPhase =
    ''
      # Some basic testing
      "$out/bin/firefox" --version
    '';

  meta = {
    description = "A web browser" + lib.optionalString (pname == "firefox-esr") " (Extended Support Release)";
    homepage = http://www.mozilla.com/en-US/firefox/;
    maintainers = with lib.maintainers; [ eelco ];
    platforms = lib.platforms.linux;
  };

  passthru = {
    inherit nspr version updateScript;
    gtk = gtk2;
    isFirefox3Like = true;
    browserName = "firefox";
    ffmpegSupport = lib.versionAtLeast version "46.0";
  };
};

in {

  firefox-unwrapped = common {
    pname = "firefox";
    version = "53.0.2";
    sha512 = "d56d563db7e1a0faa2de9315b71b479adb9109624d0958224ad2cee331dcbdb4f414380bd91f70ee0b3e543eca812c172eb2d6f6b5620f6dd6f61675f5ac69d8";
    updateScript = import ./update.nix {
      attrPath = "firefox-unwrapped";
      inherit writeScript lib common-updater-scripts xidel coreutils gnused gnugrep curl;
    };
  };

  firefox-esr-unwrapped = common {
    pname = "firefox-esr";
    version = "52.1.1esr";
    sha512 = "23f88de0a084341d54aab107bbf71b965a3f5be192ec8681b8b824c7e13d47968a0e56f4acfd2d2c5487c2e4c963e75ea6aeed400add915b3fb6403ee8810374";
    updateScript = import ./update.nix {
      attrPath = "firefox-esr-unwrapped";
      versionSuffix = "esr";
      inherit writeScript lib common-updater-scripts xidel coreutils gnused gnugrep curl;
    };
  };

}
