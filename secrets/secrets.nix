let
  michael = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi6NE+7RUyZQZ2LmAiQSuL02pf1pCevuZvWwD6iWULX michael@nixos-desktop";
  host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGNXARVaxOOw//49LEFLTjZQtH0uRHwp9yvzb3Ovxqrf root@nixos-desktop";
in {
  "searxng-settings.age".publicKeys = [ michael host ];
  "caddy-env.age".publicKeys = [ michael host ];
}