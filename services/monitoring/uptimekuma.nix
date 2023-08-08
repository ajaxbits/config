{
  services.uptime-kuma = {
    enable = true;
    appriseSupport = true;
    settings.HOST = "0.0.0.0";
    settings.PORT = "4000";
  };
}
