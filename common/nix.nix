{
  config.nix = {
    settings = {
      trusted-users = [ "@wheel" ];
      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
