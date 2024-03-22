{
  config.nix = {
    settings = {
      trusted-users = ["@wheel"];
      auto-optimise-store = true;
      extra-experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
        "no-url-literals"
      ];
      log-lines = 25;
      max-free = 3000 * 1014 * 1014;
      min-free = 512 * 1014 * 1014;
      builders-use-substitutes = true;
      connect-timeout = 5;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
