{ config, pkgs, ... }:

{
  age.secrets.searxng-settings = {
    file = ../secrets/searxng-settings.age;
    mode = "0400";
  };

  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.searxng = {
    image = "searxng/searxng:latest";
    ports = [ "8888:8080" ];
    volumes = [
      "${config.age.secrets.searxng-settings.path}:/etc/searxng/settings.yml:ro"
    ];
    environment = {
      SEARXNG_BASE_URL = "https://localhost:8888";
    };
  };
}