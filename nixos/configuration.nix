{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  imports = [
    ./hardware-configuration.nix
    ./scripts.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable; 

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

  nixpkgs.overlays = [
    outputs.overlays.unstable-packages

    (self: super: {
      dwm = super.dwm.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/Tomasz-Badura/dwm-config.git";
          rev = "72916fbd5670e199ed599ca114954542b0284c59";
        };
      });

      dwmblocks = super.dwmblocks.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/Tomasz-Badura/dwmblocks-config.git";
          rev = "b2dd1af99e14220cd73a1555f076dfb51e9e2fd8";
        };
      });
    })
  ];

  services = {
    xserver = {
      enable = true;
      windowManager.dwm.enable = true;
      xkb.layout = "pl";
      resolutions = [
        {
          x = 1920;
          y = 1080;
        }
      ];
      
      videoDrivers = [ "nvidia" ];
      excludePackages = [ pkgs.xterm ];
    };

    libinput = {
      enable = true;

      touchpad = {
        naturalScrolling = true;
        accelProfile = "flat";
        accelSpeed = "0.5";
      };

      mouse = {
        accelProfile = "flat";
        accelSpeed = "0.0";
      };
    };

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
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "uinput"
      "input"
    ];
  };

  programs = {
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Any dynamically linked executables
    ];

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      powerline-fonts
      source-han-sans
      source-han-sans-japanese
      source-han-serif-japanese
      nerdfonts
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "MesloLGSDZ Nerd Font Mono" ];
        serif = [
          "Noto Serif"
          "Source Han Serif"
        ];
        sansSerif = [
          "Noto Sans"
          "Source Han Sans"
        ];
      };
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  security.polkit.enable = true;

  systemd = {
    user.services.polkit-mate-agent-1 = {
      description = "polkit-mate-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [
        "graphical-session.target"
        "xserver.service"
        "network-online.target"
      ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    libinput
    neovim
    vim
    docker
    eza
    htop
    dmenu
    dwm
    dwmblocks
    wget
    powershell
    git
    unzip
    p7zip
    pulsemixer
    neofetch
    networkmanager
    home-manager
    mate.mate-polkit
    gnumake
    gcc
    wine
    unstable.opentabletdriver
  ];

  # didn't know where to logically put these lmao
  virtualisation.docker.enable = true;
  hardware.uinput.enable = true;
  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
