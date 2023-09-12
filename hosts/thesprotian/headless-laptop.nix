{pkgs, ...}: {
  services.openssh.enable = true;
  services.upower.ignoreLid = true;
  services.logind = {
    lidSwitch = "ignore";
    extraConfig = "HandleLidSwitch=ignore";
  };
  systemd.services.disable-screen-light = {
    script = ''
      sleep 10m
      grep -q close /proc/acpi/button/lid/*/state
      if [ $? = 0 ]; then
        ${pkgs.light}/bin/light -S 0
      fi
    '';
    wantedBy = ["multi-user.target"];
  };
}
