{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  udev,
  libdrm,
  libpqxx,
  unixodbc,
  gst_all_1,
  libpulseaudio,
  libtiff,
  libxcb-cursor,
  libxcb-wm,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  qt6,
  gtk3,
  pango,
  atk,
  cairo,
  gdk-pixbuf,
  autoStart ? false,
}:

stdenv.mkDerivation rec {
  pname = "freedownloadmanager";
  version = "6.35.1.7021";

  src = fetchurl {
    url = "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
    hash = "sha256-3xaIWR6xG/TZBHs8rkS2bXzZd6dlDXmkS5l6LtBc9bA=";
  };

  unpackPhase = "dpkg-deb -x $src .";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    libdrm
    libpqxx
    unixodbc
    stdenv.cc.cc
    libtiff
    libxcb-cursor
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libpulseaudio
    qt6.qtbase
    gtk3
    pango
    atk
    cairo
    gdk-pixbuf
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-libav
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  # These are all optional Qt SQL-plugin backends FDM bundles for its
  # database storage feature (Oracle, Mimer, Firebird, MySQL) -- not needed
  # for normal download-manager use, so we ignore rather than chase exact
  # sonames that drift whenever the upstream client libs update.
  autoPatchelfIgnoreMissingDeps = [
    "libclntsh.so.23.1"
    "libmimerapi.so"
    "libfbclient.so.2"
    "libmysqlclient.so.21"
  ];

  preFixup = ''
    ln -s ${lib.getLib libtiff}/lib/libtiff.so.6 $out/freedownloadmanager/lib/libtiff.so.5

    qtWrapperArgs+=(
      --prefix QT_PLUGIN_PATH : "$out/freedownloadmanager/plugins"
      --prefix QML2_IMPORT_PATH : "$out/freedownloadmanager/qml"
      --prefix LD_LIBRARY_PATH : "$out/freedownloadmanager/lib"
    )
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    cp -r opt/freedownloadmanager $out
    cp -r usr/share $out
    ln -s $out/freedownloadmanager/fdm $out/bin/${pname}

    substituteInPlace $out/share/applications/freedownloadmanager.desktop \
      --replace-fail 'Exec=/opt/freedownloadmanager/fdm' 'Exec=${pname}' \
      --replace-warn "Icon=/opt/freedownloadmanager/icon.png" "Icon=$out/freedownloadmanager/icon.png"

    ${lib.optionalString autoStart ''
      mkdir -p $out/etc/xdg/autostart
      cp $out/share/applications/freedownloadmanager.desktop $out/etc/xdg/autostart/fdm.desktop
      substituteInPlace $out/etc/xdg/autostart/fdm.desktop \
        --replace-fail 'Exec=${pname}' 'Exec=${pname} --hidden'
    ''}
  '';
  meta = with lib; {
    description = "A smart and fast internet download manager";
    homepage = "https://www.freedownloadmanager.org";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
