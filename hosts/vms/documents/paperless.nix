{
  services.paperless = {
    enable = true;
    user = "paperless";
    mediaDir = "/data/media"; # TODO
    consumptionDirIsPublic = true;

    address = "0.0.0.0";
    settings = {
      PAPERLESS_CONSUMER_ASN_BARCODE_PREFIX = "ZB";
      PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
      PAPERLESS_TIME_ZONE = "America/Chicago";
    };
  };
  users.users = {
    paperless = {
      isSystemUser = true;
      group = "paperless";
      extraGroups = [ "documentsoperators" ];
    };
  };
  users.groups = {
    paperless = { };
    documentsoperators = { };
  };
}
