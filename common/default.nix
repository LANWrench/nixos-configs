# Every machine, period — imported by EVERY host, including WSL.
# Rule: only things that make sense on a machine with no display and no
# physical hardware belong here. Each file holds both the system side and the
# user (home-manager) side of its topic.
{
  imports = [
    ./system.nix # Nix settings, SSH daemon, polkit, dbus, FUSE
    ./user.nix # michael's account + home-manager basics
    ./cli.nix # Shared CLI packages and tools (tmux, fzf, btop, claude-code)
    ./shell.nix # fish, bash
    ./starship.nix # Prompt
    ./neovim # Neovim (+ config.lua)
    ./git.nix # Git identity — defined ONCE
    ./ssh.nix # SSH client aliases for the homelab fleet
  ];
}
