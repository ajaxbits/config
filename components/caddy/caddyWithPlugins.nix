{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs) fetchFromGitHub;
  inherit (pkgs.stdenv) mkDerivation;

  version = "2.7.5";

  caddy275 = fetchFromGitHub {
    owner = "caddyserver";
    repo = "caddy";
    rev = "7e52db8280dcf855e77be6de5bccf7e8a173450c";
    hash = "sha256-rCQaTOTZ9LpvBNVSOLUGX9ce6U8aIabuLCqo+myE/yY=";
  };

  cloudflarePlugin = fetchFromGitHub {
    owner = "caddy-dns";
    repo = "cloudflare";
    rev = "737bf003fe8af81814013a01e981dc8faea44c07";
    hash = "sha256-g98bJ9Ac6VgE8yh852leLaYWWLne3yoliuvMdz2ypC8=";
  };
  tailscalePlugin = fetchFromGitHub {
    owner = "tailscale";
    repo = "caddy-tailscale";
    rev = "07491c582411adee9deda2b6cc784a8e6185bb60";
    hash = "sha256-eRW/N1+/tSh+O1Cis8+Z2Gun5FWZYtn3DWGvfUC8DL0=";
  };

  plugins = [
    "github.com/caddyserver/caddy/v2=${caddy275}"
    "github.com/caddy-dns/cloudflare=${cloudflarePlugin}"
    "github.com/tailscale/caddy-tailscale=${tailscalePlugin}"
  ];
in
  mkDerivation {
    inherit plugins version;

    pname = "caddy";
    dontUnpack = true;

    nativeBuildInputs = with pkgs; [git go xcaddy];

    configurePhase = ''
      export GOCACHE=$TMPDIR/go-cache
      export GOPATH="$TMPDIR/go"
    '';

    buildPhase = let
      pluginArgs = lib.concatMapStringsSep " " (plugin: "--with ${plugin}") plugins;
    in ''
      runHook preBuild
      xcaddy build "v${version}" ${pluginArgs}
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      mv caddy $out/bin
      runHook postInstall
    '';
  }
