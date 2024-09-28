{ lib, stdenv, fetchgit, plymouth-themes }:

let
  boingball = stdenv.mkDerivation {
    pname = "boingball-theme";
    version = "1.0";
    src = fetchgit {
      url = "git@github.private.net:Tomasz-Badura/BoingBallTheme.git";
      rev = "e7998beb769dbf98cb8d2312fc2bc46e00b37732";
      sha256 = lib.fakeSha256;
    };

    installPhase = ''
      mkdir -p $out/share/plymouth/themes
      cp -r $src/* $out/share/plymouth/themes/boingball
    '';

    meta = with lib; {
      description = "BoingBall Plymouth Theme";
      license = licenses.mit;
      maintainers = with maintainers; [ your-name ];
    };
  };
in
plymouth-themes.overrideAttrs (oldAttrs: {
  themes = oldAttrs.themes ++ [ boingball ];
})
