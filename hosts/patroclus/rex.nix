{ user, ... }:
let
  # Tailscale login of the Mac running the Rex app.
  principal = "tailscale:ajaxbits@github";
in
{
  # The login server maps tailnet callers to system accounts, so sessions run
  # as ${user} with a real PAM login instead of as a shared `rex` account.
  services.rex.loginServer = {
    enable = true;
    accounts.${user}.principals = [ principal ];
    defaults.${principal} = user;
    # Serves on tailnet HTTPS port 7297; Rex clients try 443 and 7297.
    tailscaleServe.enable = true;
  };
}
