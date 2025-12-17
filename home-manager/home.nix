{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  nixpkgs = {
    overlays = [ outputs.overlays.unstable-packages ];

    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "nexar";
    homeDirectory = "/home/nexar";
  };

  home.packages = with pkgs; [
    unstable.vscode # code editor
    microsoft-edge # browser
    google-chrome # browser
    pcmanfm # file explorer
    unstable.btop # system monitor tui
    steam # game launcher
    vesktop # discord
    obsidian # text editor
    wezterm # terminal
    pavucontrol # volume control
    mpv # media player
    feh # image viewer
    picom # compositor
    flameshot # screenshot app
    unstable.github-desktop # github client
    unstable.gimp # image editor
    unstable.lazydocker # docker desktop alternative tui
    nixfmt-rfc-style # nix formatter
    sxhkd # hotkeys
    unstable.wine # running windows apps
    brightnessctl # brightness control
    udisks2 gvfs # pcmanfm auto mounting usb drives

    (lutris.override {
      extraPkgs = pkgs: [
        unstable.wineWowPackages.unstableFull
        unstable.winetricks
      ];
    }) # gaming platform
  ];

  programs = {
    home-manager.enable = true;

    wezterm = {
      enable = true;
      extraConfig = ''
        return {
            font_size = 14.0,
            color_scheme = "Github",
            hide_tab_bar_if_only_one_tab = true,
            font = wezterm.font("MesloLGSDZ Nerd Font Mono"),
        }
      '';
    };

    git = {
      enable = true;
      userEmail = "tomaszbadurakontakt@gmail.com";
      userName = "Tomasz-Badura";
    };

    bash = {
      enable = true;
      bashrcExtra = ''
        eval $(ssh-agent -s)
        ssh-add ~/.ssh/gitssh
        clear
      '';
    };

    spicetify = {
      enable = true;
      enabledExtensions = with inputs.spicetify-nix.legacyPackages.${pkgs.system}.extensions; [
        shuffle
        adblock
      ];

      enabledCustomApps = with inputs.spicetify-nix.legacyPackages.${pkgs.system}.apps; [ ncsVisualizer ];

      theme = inputs.spicetify-nix.legacyPackages.${pkgs.system}.themes.catppuccin;
      colorScheme = "mocha";
    };
  };

  services = {
    picom = {
      enable = true;
      backend = "glx";
    };

    sxhkd = {
      enable = true;
      keybindings = {
        "mod4 + r" = pkgs.writeShellScript "reboot" "prompt 'Reboot?' 'reboot'";
        "mod4 + shift + r" = pkgs.writeShellScript "shutdown" "prompt 'Shutdown?' 'shutdown 0'";
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = [ "userapp-notepad-OZXNT2.desktop" ];
      "image/jpeg" = [ "feh.desktop" ];
      "image/png" = [ "feh.desktop" ];
      "image/gif" = [ "feh.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/avi" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
      "audio/wav" = [ "mpv.desktop" ];
      "application/pdf" = [ "microsoft-edge.desktop" ];
      "text/html" = [ "microsoft-edge.desktop" ];
      "x-scheme-handler/http" = [ "microsoft-edge.desktop" ];
      "x-scheme-handler/https" = [ "microsoft-edge.desktop" ];
      "x-scheme-handler/about" = [ "microsoft-edge.desktop" ];
      "x-scheme-handler/unknown" = [ "microsoft-edge.desktop" ];

      "application/x-shellscript" = [ "userapp-notepad-OZXNT2.desktop" ];
      "text/x-shellscript" = [ "userapp-notepad-OZXNT2.desktop" ];
      "text/x-ini" = [ "userapp-notepad-OZXNT2.desktop" ];
    };
  };

  # didn't know where to logically put these lmao
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
