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
        #programs
        microsoft-edge
        google-chrome
        vscode
        xfce.thunar
        gnome.gnome-system-monitor
        steam
        vesktop
        legendary-gl
        krita
        obsidian
        obs-studio
        (lutris.override 
        {
            extraPkgs = pkgs: 
            [
                wineWowPackages.stable
                winetricks
            ];
        })
        mangohud
        wezterm
        gparted
        pavucontrol
        
        picom
        feh
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

        picom.settings = 
        {
            # Shadows
            shadow = false;
            # shadow-radius = 7;
            # shadow-opacity = 0.75;
            # shadow-offset-x = -7;
            # shadow-offset-y = -7;
            # shadow-color = "#000000";
            # crop-shadow-to-monitor = false;

            # Fading
            fading = false;
            # fade-in-step = 0.03;
            # fade-out-step = 0.03;
            # fade-delta = 10;
            # no-fading-openclose = false;
            # no-fading-destroyed-argb = false;

            # Transparency / Opacity
            frame-opacity = 0.7;
            # inactive-dim-fixed = true;

            # Corners
            corner-radius = 1;

            # Blur
            # blur-method = "...";
            # blur-size = 12;
            # blur-deviation = false;
            # blur-strength = 5;
            # blur-background = false;
            # blur-background-frame = false;
            # blur-background-fixed = false;
            # blur-kern = "3x3box";

            # General Settings
            # dbus = true;
            # daemon = false;
            backend = "glx";
            dithered-present = false;
            vsync = true;
            detect-rounded-corners = true;
            detect-client-opacity = true;
            # use-ewmh-active-win = false;
            # unredir-if-possible = false;
            # unredir-if-possible-delay = 0;
            detect-transient = true;
            # detect-client-leader = false;
            use-damage = true;
            # xrender-sync-fence = false;
            # window-shader-fg = "default";
            # force-win-blend = false;
            # no-ewmh-fullscreen = false;
            # max-brightness = 1.0;
            # transparent-clipping = false;
            # log-level = "warn";
            # log-file = "/path/to/your/log/file";
            # write-pid-path = "/path/to/your/log/file";

            # Rules
            rules = 
            [
                {
                    match = "window_type = 'tooltip'";
                    fade = false;
                    shadow = true;
                    opacity = 0.75;
                    full-shadow = false;
                }
                {
                    match = "window_type = 'dock' || window_type = 'desktop' || _GTK_FRAME_EXTENTS@";
                    blur-background = false;
                }
                {
                    match = "window_type != 'dock'";
                }
                {
                    match = "window_type = 'dock' || window_type = 'desktop'";
                    corner-radius = 0;
                }
                {
                    match = "name = 'Notification' || class_g = 'Conky' || class_g ?= 'Notify-osd' || class_g = 'Cairo-clock' || _GTK_FRAME_EXTENTS@";
                    shadow = false;
                }
            ];
        };

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

    # didn't know where to logically put these lmao
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "24.05";
}
