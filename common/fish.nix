{pkgs, ...}: {
  environment.shells = [pkgs.fish];
  users.defaultUserShell = pkgs.fish;

  programs.fish = {
    enable = true;
    shellAbbrs = {
      "nixtrash" = "nix-collect-garbage -d";
      "dnixtrash" = "sudo nix-collect-garbage -d";
      "lg" = "${pkgs.lazygit}/bin/lazygit";
    };

    shellAliases = {
      ls = "${pkgs.eza}/bin/eza";
      l = "${pkgs.eza}/bin/eza -lahF --git --no-user --group-directories-first --color-scale";
      la = "${pkgs.eza}/bin/eza -lahF --git";
      cat = "${pkgs.bat}/bin/bat -pp";
      z = "pazi_cd";
    };

    interactiveShellInit = ''
      fish_vi_key_bindings
      set fish_greeting
      set fish_cursor_insert line

      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

      function pazi_cd
          if [ (count $argv) -eq 0 ]
              ${pkgs.pazi}/bin/pazi view
              return $status
          else
              set -l res (env __PAZI_EXTENDED_EXITCODES=1 ${pkgs.pazi}/bin/pazi jump $argv)
              set -l ret $status
              switch $ret
              case 90; echo $res
              case 91; cd $res
              case 92; echo $res; and return 1
              case 93; return 1
              case '*'
                  echo $res; and return $ret
              end
          end
      end

      function __pazi_preexec --on-variable PWD
          status --is-command-substitution; and return
          ${pkgs.pazi}/bin/pazi visit (pwd)
      end
    '';
  };

  programs.starship = {
    enable = true;
    interactiveOnly = true;
  };
}
