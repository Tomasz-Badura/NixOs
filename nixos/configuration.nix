{ config, lib, pkgs, inputs, outputs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
  [
    ./hardware-configuration.nix
    ./scripts.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

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

  services = {
    libinput.enable = true;
    
    xserver.enable = true;
    xserver.windowManager.dwm.enable = true;
    xserver.xkb.layout = "us";
    xserver.resolutions = [{x = 1920; y = 1080; }];
    xserver.excludePackages = [ pkgs.xterm ];

    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "terminator";
  };

  hardware.pulseaudio.enable = true;

  networking = {
    hostName = "TERMINATOR";
    enableIPv6 = false;
    networkmanager.enable = true;
  };

  users.users.terminator = {
    initialPassword = "initpass";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "uinput" "input" ];
  };

  programs = {
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Any dynamically linked executables
    ];

    steam = 
    {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  fonts = 
  {
    packages = with pkgs; 
    [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      powerline-fonts
      source-han-sans
      source-han-sans-japanese
      source-han-serif-japanese
    ];

    fontconfig = 
    {
      enable = true;
      defaultFonts = 
      {
        monospace = [ "Ubuntu Mono derivative Powerline" ];
        serif = [ "Noto Serif" "Source Han Serif" ];
        sansSerif = [ "Noto Sans" "Source Han Sans" ];
      };
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

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

  nixpkgs.overlays = [
    (self: super: {
      dwm = super.dwm.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/Tomasz-Badura/dwm-config.git";
          rev = "d72882f209e0342f0f747f82eb91ece72c499e7d";
        }; 
      });

      dwmblocks = super.dwmblocks.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/Tomasz-Badura/dwmblocks-config.git";
          rev = "ae6335a80650a6b823726b169709d3a51a6e02b4";
        };
      });
    })
  ];

  # didn't know where to logically put these lmao
  virtualisation.docker.enable = true;
  hardware.uinput.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05"; 
}
