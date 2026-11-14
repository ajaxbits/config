{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
let
  helium = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
  systemctl = "${config.systemd.package}/bin/systemctl";

  # Used only by the headless session below; the console config lives in monitor.nix.
  swayConfig = pkgs.writeText "sway-headless.conf" ''
    output * resolution 1920x1080
    default_border none
    focus_follows_mouse no
    # sway's own env (WAYLAND_DISPLAY has an auto-picked name) must reach the
    # user manager before helium/wayvnc start.
    exec ${systemctl} --user import-environment WAYLAND_DISPLAY SWAYSOCK && ${systemctl} --user start helium.service
  '';
in
{
  # Start the user manager at boot so the browser runs without a login session.
  users.users.${user}.linger = true;

  systemd.user.services = {
    sway-headless = {
      description = "Headless sway session for the omp browser";
      wantedBy = [ "default.target" ];
      # sway runs `exec` lines via `sh -c`.
      path = [ pkgs.bash ];
      environment = {
        WLR_BACKENDS = "headless";
        WLR_LIBINPUT_NO_DEVICES = "1";
        WLR_RENDERER = "pixman";
      };
      serviceConfig = {
        ExecStart = "${config.programs.sway.package}/bin/sway --config ${swayConfig}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Started by sway's `exec` above (needs WAYLAND_DISPLAY), not wantedBy anything.
    helium = {
      description = "Helium browser driven by the omp relay extension";
      bindsTo = [ "sway-headless.service" ];
      after = [ "sway-headless.service" ];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${helium}/bin/helium"
          "--ozone-platform=wayland"
          "--disable-gpu"
          "--password-store=basic"
          "--no-first-run"
          "--no-default-browser-check"
          "--load-extension=%h/.omp/browser-relay/extension"
        ];
        Restart = "always";
        RestartSec = 5;
      };
    };

    # On demand only: `systemctl --user start wayvnc`. Loopback, no auth.
    wayvnc = {
      description = "VNC view of the headless sway session (loopback only)";
      bindsTo = [ "sway-headless.service" ];
      after = [ "sway-headless.service" ];
      serviceConfig.ExecStart = "${pkgs.wayvnc}/bin/wayvnc 127.0.0.1 5900";
    };
  };
}
