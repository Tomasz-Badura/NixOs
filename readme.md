## My NixOs related config files
### for dwm: https://github.com/Tomasz-Badura/dwm-config
### for dwmblocks: https://github.com/Tomasz-Badura/dwmblocks-config

- git clone https://github.com/Tomasz-Badura/NixOs.git
- sudo mkdir /config
- sudo mv ./NixOs /config
- rm -rf ./NixOs
- sudo nixos-rebuild switch --flake /config
- sudo home-manager switch --flake /config
- reboot