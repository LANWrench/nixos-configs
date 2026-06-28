{ config, pkgs, ... }:

{
  # Enable libvirt daemon for VM management
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;  # TPM emulation (required for Windows 11)
      # OVMF (UEFI firmware) is now included by default
    };
  };

  # Enable USB redirection for VMs (allows passing USB devices to guests)
  virtualisation.spiceUSBRedirection.enable = true;

  # Virtualization packages
  environment.systemPackages = with pkgs; [
    qemu              # Hypervisor - virtualizes hardware and runs VMs
    virt-manager      # GUI for creating and managing VMs
    virt-viewer       # Lightweight viewer for VM consoles
    spice             # SPICE client libraries - remote display protocol for VMs
    spice-gtk         # GTK widget implementing SPICE protocol
    spice-protocol    # SPICE protocol headers for compatibility
    virtio-win        # Paravirtualized drivers for Windows guests (improves performance)
    win-spice         # SPICE guest agent for Windows (clipboard, resolution, mouse integration)
  ];
}
