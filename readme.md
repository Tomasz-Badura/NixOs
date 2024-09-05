## My NixOs related config files
### for dwm: https://github.com/Tomasz-Badura/dwm-config
### for dwmblocks: https://github.com/Tomasz-Badura/dwmblocks-config

- set configuration.nix hostName and create a user (all the files assume user terminator and hostName TERMINATOR)
- sudo nixos-rebuild switch (if you're switching your config, otherwise nix-install in /mnt and don't forget to add git to packages and enable networkmanager)
- cd ~
- git clone https://github.com/Tomasz-Badura/NixOs.git
- sudo mkdir /config
- sudo cp -r ./NixOs/* /config
- mv ./NixOs ./config
- sudo cp /etc/nixos/hardware-configuration.nix /config/nixos
- sudo nixos-rebuild switch --flake /config
- home-manager switch --flake /config
- reboot