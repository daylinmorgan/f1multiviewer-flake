{
  stdenvNoCC,
  fetchzip,
  lib,
  makeWrapper,
  makeDesktopItem,
  xdg-utils,
  ...
}:
stdenvNoCC.mkDerivation rec {
  name = "f1multiviewer";
  version = "1.35.2";

  src = fetchzip {
    url = "https://releases.multiviewer.app/download/180492851/MultiViewer.for.F1-linux-x64-1.35.2.zip";
    hash = "sha256-APPc0jEYO1zn25XCNg6f6bCAfDI3FsqupnIpcalfUzk=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ xdg-utils ];
  desktopItem = makeDesktopItem {
    name = "f1multiviewer";
    exec = "f1multiviewer %U";
    icon = "f1multiviewer";
    desktopName = "MultiViewer for F1";
  };

  installPhase = ''
    install -Dm0644 {${desktopItem},$out}/share/applications/f1multiviewer.desktop
    install -Dm0644 $src/resources/app/.webpack/main/88a36af69fdc182ce561a66de78de7b1.png \
      $out/share/pixmaps/f1multiviewer.png
    mkdir -p $out/bin/
    ln -s $src/'MultiViewer for F1' $out/bin/f1multiviewer
  '';

  postFixup = ''
    wrapProgram $out/bin/f1multiviewer \
      --set PATH ${lib.makeBinPath [ xdg-utils ]}
  '';
}
