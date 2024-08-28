## My NixOs related config files
### for dwm: https://github.com/Tomasz-Badura/dwm-config
### for dwmblocks: https://github.com/Tomasz-Badura/dwmblocks-config

- cd (your-repo-path) ex: ~/
- git clone https://github.com/Tomasz-Badura/NixOs.git
/config can be changed (don't forget to change reference to it in scripts.nix etc.)
- sudo mkdir /config
- sudo cp -r ./NixOs/* /config
- sudo nixos-rebuild switch --flake /config
- sudo home-manager switch --flake /config
- reboot

from here you can fork/copy the config to your own repo, change the origin for (your-repo-path/NixOs)
and then run:
- nixconfig (your-repo-path) ex: ~/NixOs

it will open vscode as sudo in /config, when vscode closes it will copy /config to provided path, change to that dir and run git add, git stage, git commit with current nixos generation, then rebuild nixos and home-manager.
