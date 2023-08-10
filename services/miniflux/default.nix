{
  services.miniflux = {
    enable = true;
    config = {
      CLEANUP_FREQUENCY = "48";
      LISTEN_ADDR = "0.0.0.0:6000";
    };
  }; 
} 