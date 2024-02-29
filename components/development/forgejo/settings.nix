{domain}: {
  global = {
    APP_NAME = "ajax forge";
  };
  session = {
    COOKIE_SECURE = true;
  };
  server = {
    DOMAIN = domain;
    ROOT_URL = "https://${domain}";
    HTTP_PORT = 3333;
    HTTP_HOST = "127.0.0.1";
    DISABLE_REGISTRATION = true;
  };
}
