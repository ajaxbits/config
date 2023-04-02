{
  lib,
  dataDir ? "/data",
  useIpv6 ? false,
}: {
  services.calibre-web = {
    enable = true;
    listen.ip = lib.mkIf (useIpv6 == false) "0.0.0.0";
    openFirewall = true;
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
      calibreLibrary = "${dataDir}/books";
    };
  };
}
