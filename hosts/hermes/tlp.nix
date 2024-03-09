{
  services.tlp = {
    enable = true;
    settings = {
      "CPU_BOOST_ON_AC" = 1;
      "CPU_BOOST_ON_BAT" = 0;
      "CPU_MAX_PERF_ON_AC" = 100;
      "CPU_MAX_PERF_ON_BAT" = 50;
      "CPU_MIN_PERF_ON_AC" = 0;
      "CPU_MIN_PERF_ON_BAT" = 0;
      "CPU_SCALING_GOVERNOR_ON_BAT" = "powersave";
      "ENERGY_PERF_POLICY_ON_AC" = "performance";
      "ENERGY_PERF_POLICY_ON_BAT" = "power";
      "MAX_LOST_WORK_SECS_ON_AC" = 15;
      "MAX_LOST_WORK_SECS_ON_BAT" = 60;
      "NMI_WATCHDOG" = 0;
      "PCIE_ASPM_ON_AC" = "default";
      "PCIE_ASPM_ON_BAT" = "powersave";
      "RESTORE_DEVICE_STATE_ON_STARTUP" = 0;
      "RUNTIME_PM_ON_AC" = "on";
      "RUNTIME_PM_ON_BAT" = "auto";
      "SCHED_POWERSAVE_ON_AC" = 0;
      "SCHED_POWERSAVE_ON_BAT" = 1;
      "SOUND_POWER_SAVE_CONTROLLER" = "Y";
      "SOUND_POWER_SAVE_ON_AC" = 0;
      "SOUND_POWER_SAVE_ON_BAT" = 1;
      "START_CHARGE_THRESH_BAT0" = 75;
      "STOP_CHARGE_THRESH_BAT0" = 97;
      "USB_AUTOSUSPEND" = 1;
      "WIFI_PWR_ON_AC" = "off";
      "WIFI_PWR_ON_BAT" = "on";
    };
  };
}
