{
  programs.centerpiece = {
    enable = true;
    config.plugin = {
      brave_progressive_web_apps.enable = false;
      git_repositories.enable = false;
    };
    services.index-git-repositories.enable = false;
  };
}
