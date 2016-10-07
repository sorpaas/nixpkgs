{ stdenv, perl, ronn, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "geteltorito-${version}";
  version = "0.6";

  src = fetchFromGitHub {
      owner = "Profpatsch";
      repo = "geteltorito";
      rev = version;
      sha256 = "05bcn3pam29xmsz1ykyqsdbkz8y23kcrvvhm987f65wd1g741f75";
  };

  buildInputs = [ perl ronn ];

  unpackCmd = "";
  dontBuild = true;
  configurePhase = "";
  installPhase = ''
    # reformat README to ronn markdown
    cat > README.new <<EOF
    geteltorito -- ${meta.description}
    ===========

    ## SYNOPSIS

    EOF

    # skip the first two lines
    # -e reformat function call
    # -e reformat example
    # -e make everything else (that is no code) that contains `: ` a list item
    tail -n +3 README | sed \
        -e 's/^\(call:\s*\)\(getelt.*\)$/\1`\2`/' \
        -e 's/^\(example:\s*\)\(getelt.*\)$/\1 `\2`/' \
        -e 's/^\(.*: \)/- \1/g' \
           >> README.new
    mkdir -p $out/man/man1
    ronn --roff README.new --pipe > $out/man/man1/geteltorito.1
    install -vD geteltorito $out/bin/geteltorito
  '';

  meta = with stdenv.lib; {
    description = "Extract the initial/default boot image from a CD image if existent";
    homepage = "https://userpages.uni-koblenz.de/~krienke/ftp/noarch/geteltorito/";
    maintainer = [ maintainers.profpatsch ];
    license = licenses.gpl2;
  };

}
