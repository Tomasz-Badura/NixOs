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
            frame-opacity = 0.7;
            corner-radius = 3;
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
