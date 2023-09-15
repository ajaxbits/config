{pkgs, ...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user.name = "Alex Jackson";
      user.email = "contact@ajaxbits.com";

      init.defaultBranch = "main";
      pull.rebase = false;

      core.pager = "${pkgs.delta}/bin/delta";
      interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
    };
  };
}
