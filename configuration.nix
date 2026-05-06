{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix

    # System modules
    ./modules/snapper.nix
    ./modules/restic.nix
    ./modules/auto-update.nix
    ./modules/virtualization.nix

    # Containers
    ./modules/searxng.nix

    # ========================================
    # DESKTOP ENVIRONMENT - Choose one below
    # ========================================
    # Comment out the one you're NOT using

    ./desktops/niri.nix
    # ./desktops/kde.nix
    # ./desktops/cosmic.nix
  ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow root (auto-update service) to access user-owned Git repository
  # Without this, nixos-upgrade.service fails with "repository path is not owned by current user"
  programs.git = {
    enable = true;
    config = {
      safe.directory = "/home/michael/nixos-config";
    };
  };
  # Allow my regular user to read a FUSE mount
  programs.fuse.userAllowOther = true;

  # Boot configuration
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
  };

  # Hardware configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Networking
  networking.hostName = "nixos-desktop";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 53317 ]; # LocalSend

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Time zone
  time.timeZone = "America/Chicago";

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # BTRFS auto-scrub
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Users
  users.users.michael = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "cdrom" "libvirtd" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
    #  "public-key-goes-here"
    ];
  };

  programs.fish.enable = true;

  # Gaming applications needed at system level
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # Common system packages (desktop-agnostic)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    keyutils
    gparted
    ripgrep
    inputs.agenix.packages."x86_64-linux".default
    fuse
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Nvidia-specific Wayland variables
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    __GL_THREADED_OPTIMIZATION = "1";
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.caskaydia-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.hack
    nerd-fonts.blex-mono
    nerd-fonts.meslo-lg
    nerd-fonts.roboto-mono
    ibm-plex
    noto-fonts
    corefonts
    vista-fonts
  ];

  # Security
  security.polkit.enable = true;

  # Enable CD/DVD burning with proper capabilities
  security.wrappers.cdrecord = {
    source = "${pkgs.cdrtools}/bin/cdrecord";
    capabilities = "cap_sys_resource,cap_dac_override,cap_sys_admin,cap_sys_nice,cap_net_bind_service,cap_ipc_lock,cap_sys_rawio+eip";
    owner = "root";
    group = "cdrom";
    permissions = "u+rx,g+x";
  };

  services.dbus.enable = true;

  # USB udev rules
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0066", ATTR{power/control}="on"
  '';

  # Fix Elgato Cam Link 4K
  boot.extraModprobeConfig = ''
    options uvcvideo nodrop=0
    options uvcvideo quirks=0
  '';

  system.stateVersion = "25.05";
}
