{
  services.writefreely = {
    enable = true;
    host = "posts.ajax.lol";
    admin = {
      name = "ajaxbits";
    };
    settings = {
      app = {
        single_user = true;
        site_description = "Alex's blog.";
        site_name = "posts";
      };
      server = {
        port = 8155;
      };
    };
  };
}
