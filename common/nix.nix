{
  config.nix = {
    settings.trusted-users = ["@wheel"];
    settings.auto-optimise-store = true;
    settings.extra-experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
