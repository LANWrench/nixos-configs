{ inputs, ... }:

# Platform: NixOS running under Windows Subsystem for Linux (WSL2).
# WSL provides its own kernel, networking, and (via WSLg) display, so this
# host must NOT import platform/physical.nix — no audio, NetworkManager,
# printing, fonts, or hardware files.
#
# Note: the Linux hostname (networking.hostName, set by mkHost) is separate
# from the WSL *distribution* name that Windows registers (the name you pass
# to `wsl --import <Name> ...`, seen in `wsl -l -v`). They can differ freely.

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl.enable = true;
  # The user WSL logs in as by default (`wsl` with no -u). Must match a
  # declared user account (common/user.nix).
  wsl.defaultUser = "michael";
}
