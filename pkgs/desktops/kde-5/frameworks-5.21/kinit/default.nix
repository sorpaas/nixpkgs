{ kdeFramework, lib, copyPathsToStore, extra-cmake-modules, kconfig, kcrash
, kdoctools, ki18n, kio, kservice, kwindowsystem, libcap
}:

kdeFramework {
  name = "kinit";
  nativeBuildInputs = [ extra-cmake-modules kdoctools libcap.out ];
  buildInputs = [ kconfig kcrash kservice libcap ];
  propagatedBuildInputs = [ ki18n kio kwindowsystem ];
  patches = copyPathsToStore (lib.readPathsFromFile ./. ./series);
  meta = {
    maintainers = [ lib.maintainers.ttuegel ];
  };
}
