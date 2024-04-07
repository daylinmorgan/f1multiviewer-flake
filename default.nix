{
  stdenvNoCC,
  fetchzip,
  lib,
  makeWrapper,
  makeDesktopItem,
  xdg-utils,
}:
stdenvNoCC.mkDerivation rec {
  name = "f1multiviewer";
  version = "1.37.7";

  src = fetchzip {
    url = "https://releases.multiviewer.app/download/155752212/MultiViewer.for.F1-linux-x64-1.31.7.zip";
    hash = "sha256-0XI2LtOXmtHd/vKJ49l34V9macMBh7bfWWBLLhF02Io=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ xdg-utils ];
  desktopItem = makeDesktopItem {
    name = "f1multiviewer";
    exec = "f1multiviewer %U";
    icon = "f1multiviewer";
    desktopName = "MultiViewer for F1";
  };

  # logo here MultiViewer%20for%20F1-linux-x64/resources/app/.webpack/main/88a36af69fdc182ce561a66de78de7b1.png
  installPhase = ''
    install -Dm0644 {${desktopItem},$out}/share/applications/f1multiviewer.desktop
    install -Dm0644 $src/resources/app/.webpack/main/88a36af69fdc182ce561a66de78de7b1.png \
      $out/share/icons/hicolor/apps/f1multiviewer.png
    mkdir -p $out/bin/
    ln -s $src/'MultiViewer for F1' $out/bin/f1multiviewer
  '';
  postFixup = ''
    wrapProgram $out/bin/f1multiviewer \
      --set PATH ${lib.makeBinPath ([ xdg-utils ])}
  '';
}
