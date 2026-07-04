{ config, pkgs, ... }:

# Universal system base — imported by EVERY host, including WSL.
# Rule: only things that make sense on a machine with no display
# and no physical hardware belong here. Hardware-dependent defaults
# (audio, NetworkManager, printing) live in profiles/physical.nix.

{
  imports = [
    ./core.nix
    ./nix.nix
    ./security.nix
  ];
}
