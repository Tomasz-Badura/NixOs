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

  boot = {
    # plymouth = 
    # let 
    # plymouth-theme = import ../drv/plymouth_theme.nix { inherit pkgs; };
    # in
    # {
    #   enable = true;
    #   theme = "BoingBall";
    #   themePackages = [
    #     plymouth-theme
    #   ];
    # };

    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/win" = {
      device = "dev/nvme0n1p3";
      fsType = "ntfs";
      options = [
        "users"
        "nofail"
        "x-gvfs-show"
      ];
    };
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = true;
      open = false;
      nvidiaSettings = true;
      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    uinput.enable = true;

    opengl.enable = true;
    opengl.driSupport32Bit = true;

    opentabletdriver.enable = true;
    opentabletdriver.daemon.enable = true;
  };

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
          rev = "ebcdda2a08143e6b40e20ad1780a24b88ee0c0f6";
        };
      });

      dwmblocks = super.dwmblocks.overrideAttrs (oldattrs: {
        src = fetchGit {
          url = "https://github.com/Tomasz-Badura/dwmblocks-config.git";
          rev = "00692752bd806d251cd4001e32f1b3419874692b";
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

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
        PermitEmptyPasswords = false;
        MaxAuthTries = 3;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        port = 32;
      };
    };

    displayManager.autoLogin = {
      enable = true;
      user = "terminator";
    };

    fail2ban.enable = true;
  };

  hardware.pulseaudio.enable = true;

  networking = {
    hostName = "TERMINATOR";
    enableIPv6 = false;
    networkmanager.enable = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 32 ];
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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZiSMswBK0/ithgyMfg5YKMadOTW+ys9zoQxWEPlf/k tomaszbadurakontakt@gmail.com"
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
    fail2ban
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
    fzf
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
    unstable.opentabletdriver
    xwallpaper
    plymouth
  ];

  # didn't know where to logically put these lmao
  virtualisation.docker.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
