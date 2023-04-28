{pkgs, ...}: {
  services.caddy = {
    enable = true;
    virtualHosts."agamemnon.spotted-python.ts.net".extraConfig = ''
      encode gzip
      file_server
      root * ${
        pkgs.runCommand "testdir" {} ''
          mkdir "$out"
          echo hello world > "$out/example.html"
        ''
      }
    '';
  };
}
