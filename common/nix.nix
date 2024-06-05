{
  config.nix = {
    settings = {
      trusted-users = ["@wheel"];
      auto-optimise-store = true;
      extra-experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
