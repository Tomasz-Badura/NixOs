{ inputs, outputs, lib, config, pkgs, ... }: 

{
    imports = 
    [
        inputs.spicetify-nix.homeManagerModules.default
        inputs.xremap-flake.homeManagerModules.default
    ];

    nixpkgs = 
    {
        overlays = 
        [

        ];

        config = {
            allowUnfree = true;
        };
    };

    home = 
    {
        username = "terminator";
        homeDirectory = "/home/terminator";
    };
    
    home.packages = with pkgs; 
    [ 
        microsoft-edge # browser
        google-chrome # browser
        vscode # code editor
        pcmanfm # file explorer
        kdePackages.plasma-systemmonitor # system monitor
        steam # game launcher
        vesktop # discord
        krita # painting program
        obsidian # text editor
        obs-studio # screen recording
        (lutris.override 
        {
            extraPkgs = pkgs: 
            [
                wineWowPackages.stable
                winetricks
            ];
        }) # gaming platform
        mangohud # overlay for monitoring
        wezterm # terminal
        gparted # partition editor
        pavucontrol # volume control
        mpv # media player
        reaper # DAW
        feh # image viewer
        picom # compositor
        flameshot # screenshot app
        github-desktop # github client
        unityhub # unity game engine
        gimp # image editor
        kdePackages.kdenlive # video editor
        audacity # audio recorder and editor
    ];

    programs = 
    {
        home-manager.enable = true;
        
        git = 
        {
            enable = true;
            userEmail="tomaszbadurakontakt@gmail.com";
            userName="Tomasz Badura";
        };

        spicetify =
        {
            enable = true;
            enabledExtensions = with inputs.spicetify-nix.legacyPackages.${pkgs.system}.extensions; [
                shuffle
                adblock
            ];

            enabledCustomApps = with inputs.spicetify-nix.legacyPackages.${pkgs.system}.apps; [
                ncsVisualizer
            ];

            theme = inputs.spicetify-nix.legacyPackages.${pkgs.system}.themes.catppuccin;
            colorScheme = "mocha";
        };
    };

    services = 
    {
        picom.enable = true;
        xremap = 
        {
            withX11 = true;
            yamlConfig = 
            ''
                modmap
                - name: global modmap
                keymap
                - name: global keymap
            '';
        };
    };

    xdg.mimeApps = 
    {
        enable = true;
        defaultApplications = 
        {
            #"text/plain" = [ "nvim.desktop" "gedit.desktop" ];
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
