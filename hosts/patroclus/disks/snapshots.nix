{
  services.sanoid = {
    enable = true;
    interval = "hourly";
    templates = {
      default = {
        autosnap = true;
        autoprune = true;
        hourly = 0;
        daily = 7;
        weekly = 4;
        monthly = 3;
        yearly = 0;
        daily_hour = 23;
        daily_min = 50;
      };
      infrequent = {
        autosnap = true;
        autoprune = true;
        hourly = 0;
        daily = 0;
        weekly = 1;
        monthly = 1;
        yearly = 0;
        daily_hour = 23;
        daily_min = 50;
      };
    };

    datasets =
      let
        useTemplate =
          template: paths:
          builtins.listToAttrs (
            map (item: {
              name = item;
              value = {
                useTemplate = [ template ];
              };
            }) paths
          );
      in
      {
        "zroot/srv/media/audiobooks" = {
          autosnap = true;
          autoprune = true;
          hourly = 6;
          daily = 3;
          weekly = 2;
          monthly = 2;
          yearly = 1;
          daily_hour = 23;
          daily_min = 50;
        };
      }
      // useTemplate "default" [
        "zroot/srv/config"
        "zroot/srv/containers"
        "zroot/srv/documents"
        "zroot/srv/media"
        "zroot/system/var"
      ]
      // useTemplate "infrequent" [
        "zroot/local/log"
        "zroot/local/nix"
        "zroot/system/root"
      ];
  };
}
