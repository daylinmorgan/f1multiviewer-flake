{
  stdenvNoCC,
  fetchzip,
  makeWrapper,
  makeDesktopItem,
  # xdg-utils,
  ...
}:
stdenvNoCC.mkDerivation rec {
  name = "f1multiviewer";
  version = "1.36.1";

  src = fetchzip {
    url = "https://releases.multiviewer.app/download/192684464/MultiViewer.for.F1-linux-x64-1.36.1.zip";
    hash = "sha256-8xUhfYM9db6DhEaeAMjfwGmgW5mH6ErHGyMLkbRH9l0=";
  };

  nativeBuildInputs = [ makeWrapper ];
  # buildInputs = [ xdg-utils ];
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

  # https://github.com/f1multiviewer/issue-tracker/issues/506
  # add no-sandbox flag?
  postFixup = ''
    runHook preInstall

    wrapProgram $out/bin/f1multiviewer \
      --add-flags "--no-sandbox" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-features=WaylandWindowDecorations}}" \

    runHook postInstall
  '';
}
