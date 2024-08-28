{ config, lib, pkgs, inputs, outputs, ... }:

{
  # flakes / imports
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
  [
    ./hardware-configuration.nix
    ./scripts.nix
  ];

  # grub
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # time / locale
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # services
  services = {
    libinput.enable = true;
    
    xserver.enable = true;
    xserver.windowManager.dwm.enable = true;
    xserver.xkb.layout = "us";
    xserver.resolutions = [{x = 1920; y = 1080; }];
    
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "terminator";
  };

  # fonts
  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      defaultFonts = {
        serif = [  "IosevkaTermSlab" ];
        sansSerif = [ "AurulentSansM" ];
        monospace = [ "FiraCode" ];
      };
    };
  };

  # audio
  hardware.pulseaudio.enable = true;

  # networking
  networking = {
    hostName = "TERMINATOR";
    enableIPv6 = false;
    networkmanager.enable = true;
  };

  # users
  users.users.terminator = {
    initialPassword = "initpass";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "uinput" "input" ];
  };

  # programs
  programs = {
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Any dynamically linked executables
    ];
  };

  # auth
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # polkit
  security.polkit.enable = true;
  
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = [
        "graphical-session.target"
        "xserver.service"
        "network-online.target"
      ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

  # startup script
    user.services.startup-script = {
      enable = true;
      description = "startup script";
      wantedBy = ["graphical-session.target"];
      script = ''
        dwmblocks
      '';
      serviceConfig.PassEnvironment = "DISPLAY";
      serviceConfig.Environment = "PATH=${pkgs.nix}/bin:${pkgs.dwmblocks}/bin:${pkgs.dwm}/bin:/run/current-system/sw/bin";
    };
  };

  # packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    libinput
    neovim
    vim
    docker
    eza

    dmenu
    dwm
    dwmblocks
    
    wget
    powershell
    git
    unzip
    neofetch
    networkmanager
    home-manager

    gnumake
    gcc
  ];

  # overlays
  nixpkgs.overlays = [
    (self: super: {
      dwm = super.dwm.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/Tomasz-Badura/dwm-config.git";
          rev = "537e1ab1aab9a5ff2fe715a0ba99ab293f4cede0";
        }; 
      });

      dwmblocks = super.dwmblocks.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/jitessh/dwmblocks.git";
          rev = "ab739d8780afbb6228124e1c9fe19bffac577b3e";
        };
      });
    })
  ];

  programs.steam = 
  {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # other
  virtualisation.docker.enable = true;
  hardware.uinput.enable = true;

  # https://search.nixos.org/options?channel=24.05&show=system.stateVersion&from=0&size=50&sort=relevance&type=packages&query=stateVersion
  system.stateVersion = "24.05"; 
}
