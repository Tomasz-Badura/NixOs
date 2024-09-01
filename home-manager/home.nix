{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    inputs.xremap-flake.homeManagerModules.default
  ];

  nixpkgs = {
    overlays = [ outputs.overlays.unstable-packages ];

    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "terminator";
    homeDirectory = "/home/terminator";
  };

  home.packages = with pkgs; [
    unstable.vscode # code editor
    microsoft-edge # browser
    google-chrome # browser
    pcmanfm # file explorer
    (lib.hiPrio unstable.bottom) # system monitor cli
    steam # game launcher
    vesktop # discord
    krita # painting program
    obsidian # text editor
    unstable.obs-studio # screen recording
    mangohud # overlay for monitoring
    wezterm # terminal
    pavucontrol # volume control
    mpv # media player
    feh # image viewer
    picom # compositor
    flameshot # screenshot app
    unstable.github-desktop # github client
    unstable.unityhub # unity game engine
    unstable.gimp # image editor
    unstable.kdePackages.kdenlive # video editor
    unstable.glaxnimate # kdenlive dependency
    audacity # audio recorder and editor
    unstable.lazydocker # docker desktop alternative cli
    unstable.lenovo-legion # lenovo legion toolkit alternative
    nixfmt-rfc-style # nix formatter
    # TODO DAW

    (lutris.override {
      extraPkgs = pkgs: [
        wineWowPackages.stable
        winetricks
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

    bottom = {
      enable = true;
      settings = {
        styles = {
          theme = "nord-light";
        };
      };
    };

    git = {
      enable = true;
      userEmail = "tomaszbadurakontakt@gmail.com";
      userName = "Tomasz-Badura";
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
      settings = {
        blur = {
          method = "dual_kawase";
          size = 1;
          deviation = 2;
        };
        use-damage = true;
      };
    };

    xremap = {
      withX11 = true;
      yamlConfig = ''
        modmap
        - name: global modmap
        remap:
          - shortcut: { win: "R" }
            command: "prompt 'Reboot system?' 'sudo reboot'"
        keymap
        - name: global keymap
      '';
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = [ "notepad" ];
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
    };
  };

  # didn't know where to logically put these lmao
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}
