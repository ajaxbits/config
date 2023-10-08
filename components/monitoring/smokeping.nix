{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config = lib.mkIf cfg.enable {
    services.smokeping.enable = true;
    services.smokeping.host = "0.0.0.0";
    services.smokeping.targetConfig = ''
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to the SmokePing website of xxx Company. \
               Here you will learn all about the latency of our network.
      + Local
      menu = Local
      title = Local Network
      ++ LocalMachine
      menu = Local Machine
      title = This host
      host = localhost
      + InternetWeather
      menu = InternetWeather
      title = Internet Weather
      ++ Cloudflare
      menu = Cloudflare
      title = Cloudflare
      host = 1.1.1.1
      ++ Google
      menu = Google
      title = Google
      host = 8.8.8.8    
    '';
  };
}
