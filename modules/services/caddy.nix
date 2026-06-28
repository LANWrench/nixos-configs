{ config, pkgs, ... }:

let
  caddyWithDns = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare" ];
    hash = ""; # nix will tell you the correct hash on first build
  };
in {
  age.secrets.caddy-env = {
    file = ../../secrets/caddy-env.age;
    owner = "caddy";
    mode = "0400";
  };

  services.caddy = {
    enable = true;
    package = caddyWithDns;
    virtualHosts."search.handmc.net".extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
      reverse_proxy localhost:8888
    '';
  };

  # Pass the API token to Caddy's systemd service
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.age.secrets.caddy-env.path;
