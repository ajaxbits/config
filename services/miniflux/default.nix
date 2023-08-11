{
  self,
  config,
  ...
}: {
  services.miniflux = {
    enable = true;
    adminCredentialsFile = "${config.age.secretsDir}/miniflux/adminCredentialsFile";
    config = {
      CLEANUP_FREQUENCY = "48";
      LISTEN_ADDR = "0.0.0.0:6000";
    };
  };

  age.secrets = {
    "miniflux/adminCredentialsFile" = {
      file = "${self}/secrets/miniflux/adminCredentialsFile.age";
      mode = "440";
      owner = config.services.miniflux.user;
      group = config.services.miniflux.user;
    };
  };
}
