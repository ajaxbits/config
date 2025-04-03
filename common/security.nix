{
  environment.etc."audit/auditd.conf".text = ''
    space_left = 10%
    space_left_action = ignore
    num_logs = 10
    max_log_file = 100
    max_log_file_action = rotate
  '';
  security = {
    audit = {
      enable = true;
      rules = [ "-a always,exit -F arch=b64 -S execve" ];
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
