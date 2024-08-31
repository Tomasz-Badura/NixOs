## My NixOs related config files
### for dwm: https://github.com/Tomasz-Badura/dwm-config
### for dwmblocks: https://github.com/Tomasz-Badura/dwmblocks-config

- set configuration.nix hostName and create a user (all the files assume user terminator and hostName TERMINATOR)
- sudo nixos-rebuild switch
- cd ~
- git clone https://github.com/Tomasz-Badura/NixOs.git
- sudo mkdir /config
- sudo mv ./NixOs/* /config
- rm -rf ./NixOs
- sudo cp /etc/nixos/hardware-configuration.nix /config/nixos
- sudo nixos-rebuild switch --flake /config
- home-manager switch --flake /config
- reboot
