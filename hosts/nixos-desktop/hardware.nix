{ config, pkgs, ... }:

{
  # Boot configuration with Nvidia kernel parameters
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];
    plymouth.enable = true;

    # Fix Elgato Cam Link 4K
    extraModprobeConfig = ''
      options uvcvideo nodrop=0
      options uvcvideo quirks=0
    '';
  };

  # Hardware graphics configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Nvidia GPU configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # GPU access inside containers (CDI for features/containers.nix podman)
  hardware.nvidia-container-toolkit.enable = true;

  # CUDA build of the local LLM server (features/ollama.nix)
  services.ollama.package = pkgs.ollama-cuda;

  # Nvidia-specific environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    __GL_THREADED_OPTIMIZATION = "1";
  };

  # BTRFS auto-scrub
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Enable CD/DVD burning with proper capabilities
  security.wrappers.cdrecord = {
    source = "${pkgs.cdrtools}/bin/cdrecord";
    capabilities = "cap_sys_resource,cap_dac_override,cap_sys_admin,cap_sys_nice,cap_net_bind_service,cap_ipc_lock,cap_sys_rawio+eip";
    owner = "root";
    group = "cdrom";
    permissions = "u+rx,g+x";
  };

  # USB udev rules (specific devices)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0066", ATTR{power/control}="on"
  '';
}
