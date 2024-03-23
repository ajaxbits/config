{
  security = {
    audit = {
      enable = true;
      rules = ["-a always,exit -F arch=b64 -S execve"];
    };
    auditd.enable = true;

    sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults lecture = never
      '';
    };
  };
}
