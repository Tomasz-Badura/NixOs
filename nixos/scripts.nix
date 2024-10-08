{ config, pkgs, ... }:
let
  sb-battery = pkgs.writeShellScriptBin "sb-battery" ''
    # Description: Script to get battery status

    source sb-config

    for battery in /sys/class/power_supply/BAT?; do
        percent=$(cat "$battery/capacity") 
        status="$(cat "$battery/status")"

        [ "$status" = "Charging" ] && icon_charge="charging "
        [ "$status" = "Not charging" ] && icon_charge="idle "

        printf "%s%s%d%s" "$icon_charge" "battery " "$percent" "%"
    done && exit 0
  '';

  sb-datetime = pkgs.writeShellScriptBin "sb-datetime" ''
    # Description: Script to get current date and time
    export PATH=${pkgs.nix}/bin:/run/current-system/sw/bin:$PATH

    source sb-config

    handle_button $BUTTON "${pkgs.wezterm}/bin/wezterm start -- $SHELL -c 'run date'" "" "" "code /config/nixos/scripts.nix"

    printf "%s" "$(date +"%m.%d.%Y %A %H:%M:%S")" && exit 0

  '';

  sb-internet = pkgs.writeShellScriptBin "sb-internet" ''
    # Description: Script to get Wi-Fi and Ethernet status
    source sb-config

    if nmcli dev | grep -q 'wifi.*connected'; then
      echo "wifi"
      exit 0
    fi

    if nmcli dev | grep -q 'ethernet.*connected'; then
      echo "ethernet"
      exit 0
    fi

    echo "not connected"
    exit 0
  '';

  sb-ram = pkgs.writeShellScriptBin "sb-ram" ''
    # Description: Script to get ram usage

    source sb-config
    printf "%s%s" "ram " "$(free -mh --si | grep '^Mem:' | awk '{print $3}')" && exit 0
  '';

  sb-volume = pkgs.writeShellScriptBin "sb-volume" ''
    # Description: Script to get current volume

    source sb-config

    percent="$(pulsemixer --get-volume | awk '{print $1}')"
    printf "%s%d%s" "vol " "$percent" "%" && exit 0
  '';

  sb-config = pkgs.writeShellScriptBin "sb-config" ''
    # Description: config for sb- scripts

    handle_button() {
      local number=$1
      shift
      local commands=("$@")

      if [[ $number =~ ^[1-4]$ ]] && [[ -n "''${commands[$((number-1))]}" ]]; then
        eval "''${commands[$((number-1))]}"
      fi
    }

    text_color="^c#000000^"  # Black text
    accent_color="^c#FFB6FC^"  # Pink accent
    reset_color="^d^"  # Reset color
  '';

  sb-nixstoresize = pkgs.writeShellScriptBin "sb-nixstoresize" ''
    CACHE_FILE="/tmp/sb-nixstoresize.cache"
    CACHE_THRESHOLD=600  # 10 minutes in seconds

    get_nix_store_size() {
      du -sb /nix/store | cut -f1 | awk '{printf "%.2f\n", $1/1024/1024/1024}'
    }

    if [ -f "$CACHE_FILE" ]; then
      CACHE_TIME=$(stat -c %Y "$CACHE_FILE")
      CURRENT_TIME=$(date +%s)
      
      if [ $((CURRENT_TIME - CACHE_TIME)) -lt "$CACHE_THRESHOLD" ]; then
        echo "/nix/store: $(cat $CACHE_FILE) GB"
      else
        SIZE=$(get_nix_store_size)
        echo "$SIZE" > "$CACHE_FILE"
        echo "/nix/store: $SIZE GB"
      fi
    else
      SIZE=$(get_nix_store_size)
      echo "$SIZE" > "$CACHE_FILE"
      echo "/nix/store: $SIZE GB"
    fi
  '';

  sb-homesize = pkgs.writeShellScriptBin "sb-homesize" ''  
    CACHE_FILE="/tmp/sb-homesize.cache"
    CACHE_THRESHOLD=600  # 10 minutes in seconds

    get_home_size() {
      du -sb /home | cut -f1 | awk '{printf "%.2f\n", $1/1024/1024/1024}'
    }

    if [ -f "$CACHE_FILE" ]; then
      CACHE_TIME=$(stat -c %Y "$CACHE_FILE")
      CURRENT_TIME=$(date +%s)
      
      if [ $((CURRENT_TIME - CACHE_TIME)) -lt "$CACHE_THRESHOLD" ]; then
        echo "/home: $(cat $CACHE_FILE) GB"
      else
        SIZE=$(get_home_size)
        echo "$SIZE" > "$CACHE_FILE"
        echo "/home: $SIZE GB"
      fi
    else
      SIZE=$(get_home_size)
      echo "$SIZE" > "$CACHE_FILE"
      echo "/home: $SIZE GB"
    fi
  '';

  sb-brightness = pkgs.writeShellScriptBin "sb-brightness" ''
    # Description: Script to get current screen brightness percentage

    a=$(${pkgs.brightnessctl}/bin/brightnessctl get)
    b=$(${pkgs.brightnessctl}/bin/brightnessctl max)
    brightness=$(awk "BEGIN {printf \"%.0f\", $a / ($b / 100)}")
    printf "bright $brightness%%" && exit 0
  '';

  nixshell = pkgs.writeShellApplication {
    name = "nixshell";
    text = ''
      SHELLS_PATH="/config/nix-shells"

      nix develop $SHELLS_PATH#"$1"
    '';
  }; 

  nixconfig = pkgs.writeShellApplication { 
    name = "nixconfig";
    text = ''
      flag_norebuild=false
      flag_commit=false
      flag_skipconf=false

      while getopts "sfc" option; do
          case $option in
              s)
                  flag_norebuild=true
                  ;;
              f)
                  flag_skipconf=true
                  ;;
              c)
                  flag_commit=true
                  ;;
              *)
                  echo "Usage: nixconfig [-s] [-f] [-c value]"
                  echo "  -s            don't rebuild"
                  echo "  -f            skip rebuild confirmations, rebuild both home-manager and nixos"
                  echo "  -c            commit changes, requires cloned repo at ~/config"
                  exit 1
                  ;;
          esac
      done

      REPO_PATH="$HOME/config"

      if ! code --wait /config; then
          echo "Error opening VS Code."
          exit 1
      fi

      if $flag_commit; then
          if [ -d "$REPO_PATH" ]; then
              if ! find "$REPO_PATH" -mindepth 1 -maxdepth 1 ! -name '.*' -exec sudo rm -rf {} +; then
                  echo "Error cleaning files in $REPO_PATH"
                  exit 1
              fi

              if ! sudo cp -r /config/* "$REPO_PATH"; then
                  echo "Error copying files to $REPO_PATH"
                  exit 1
              fi

              echo "copied to $REPO_PATH"

              cd "$REPO_PATH" || { echo "Error changing directory to $REPO_PATH"; exit 1; }

              if ! git add .; then
                  echo "Error adding files to git"
                  exit 1
              fi

              NIXOS_GENERATION=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')

              if ! git commit -m "Update configuration - $NIXOS_GENERATION"; then
                  echo "Error committing changes to git"
                  exit 1
              fi

              echo "succesfully commited"
          else
              echo "skipping commit"
          fi
      fi

      if $flag_norebuild; then
          echo "finished"
          exit 0
      fi

      if $flag_skipconf; then
          if ! sudo nix flake update /config; then
              echo "Error updating flakes"
              exit 1
          fi

          if ! sudo nixos-rebuild switch --flake /config; then
              echo "Error rebuilding NixOS"
              exit 1
          fi

          if ! home-manager switch --flake /config; then
              echo "Error rebuilding Home Manager"
              exit 1
          fi
      else
          read -rp "Do you want to update flakes (y/yes to proceed)? " response
          if [[ "$response" == "y" || "$response" == "yes" ]]; then
              if ! sudo nix flake update /config; then
                  echo "Error updating flakes"
                  exit 1
              fi
          else
              echo "Skipping updating flakes."
          fi

          read -rp "Do you want to rebuild NixOS (y/yes to proceed)? " response
          if [[ "$response" == "y" || "$response" == "yes" ]]; then
              if ! sudo nixos-rebuild switch --flake /config; then
                  echo "Error rebuilding NixOS"
                  exit 1
              fi
          else
              echo "Skipping NixOS rebuild."
          fi

          read -rp "Do you want to rebuild Home Manager (y/yes to proceed)? " response
          if [[ "$response" == "y" || "$response" == "yes" ]]; then
              if ! home-manager switch --flake /config; then
                  echo "Error rebuilding Home Manager"
                  exit 1
              fi
          else
              echo "something went wrong, skipping commit (check if '$REPO_PATH' exists)"
          fi
      fi

      echo "finished succesfully"
    '';
  };

  nixrebuild = pkgs.writeShellApplication { 
    name =  "nixrebuild";
    text = ''
      flag_home=false
      flag_nixos=false
      flag_commit=false
      flag_push=false
      flag_flake_update=false
      flag_optimise=false
      flag_garbage_collect=false
      options_set=false

      while getopts "fnhcpgo" option; do
          case $option in
              f)
                  flag_flake_update=true
                  options_set=true
                  ;;
              h)
                  flag_home=true
                  options_set=true
                  ;;
              n)
                  flag_nixos=true
                  options_set=true
                  ;;
              c)
                  flag_commit=true
                  options_set=true
                  ;;
              p)
                  flag_push=true
                  options_set=true
                  ;;
              g)
                  flag_garbage_collect=true
                  options_set=true
                  ;;
              o)
                  flag_optimise=true
                  options_set=true
                  ;;
              *)
                  echo "Usage: nixrebuild [FLAGS]"
                  echo "  -f            run 'nix flake update'"
                  echo "  -n            rebuild nixos"
                  echo "  -h            rebuild home-manager"
                  echo "  -c            commit changes, requires cloned repo at ~/config"
                  echo "  -p            push changes, requires cloned repo at ~/config"
                  echo "  -g            run 'nix-collect-garbage'"
                  echo "  -o            run 'nix-store --optimise'"
                  exit 1
                  ;;
          esac
      done

      if [ "$options_set" = false ]; then
          echo "Usage: nixrebuild [-c] [-f] [-n] [-h]"
          echo "  -f            run 'nix flake update'"
          echo "  -n            rebuild nixos"
          echo "  -h            rebuild home-manager"
          echo "  -c            commit changes, requires cloned repo at ~/config"
          echo "  -p            push changes, requires cloned repo at ~/config"
          echo "  -g            run 'nix-collect-garbage'"
          echo "  -o            run 'nix-store --optimise'"
          exit 1
      fi

      REPO_PATH="$HOME/config"

      if [ "$flag_flake_update" = true ]; then
          if ! nix flake update /config; then
              echo "Error running nix flake update"
              exit 1
          fi

          echo "flake updated"
      fi

      if [ "$flag_nixos" = true ]; then
          if ! sudo nixos-rebuild switch --flake /config; then
              echo "Error rebuilding NixOS"
              exit 1
          fi

          echo "nixos rebuilt"
      fi

      if [ "$flag_home" = true ]; then
          if ! home-manager switch --flake /config; then
              echo "Error rebuilding home manager"
              exit 1
          fi
        
          echo "home-manager rebuilt"
      fi

      if [ "$flag_commit" = true ]; then
          if [ -d "$REPO_PATH" ]; then
              if ! find "$REPO_PATH" -mindepth 1 -maxdepth 1 ! -name '.*' -exec sudo rm -rf {} + ; then
                  echo "Error cleaning files in $REPO_PATH"
                  exit 1
              fi

              if ! sudo cp -r /config/* "$REPO_PATH"; then
                  echo "Error copying files to $REPO_PATH"
                  exit 1
              fi

              if ! cd "$REPO_PATH"; then
                  echo "Error changing directory to $REPO_PATH" 
                  exit 1
              fi
              
              if ! git add .; then
                  echo "Error adding files to git"
                  exit 1
              fi

              NIXOS_GENERATION=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')

              if ! git commit -m "Update configuration - $NIXOS_GENERATION"; then
                  echo "Error committing changes to git"
                  exit 1
              fi

              echo "Changes committed"
          else
              echo "Skipping commit, check if '$REPO_PATH' exists"
          fi

          cd "/config"
      fi

      if [ "$flag_push" = true ]; then
          if [ -d "$REPO_PATH" ]; then

              if ! cd "$REPO_PATH"; then
                  echo "Error changing directory to $REPO_PATH" 
                  exit 1
              fi

              if ! git push; then
                  echo "Error pushing changes to github"
                  exit 1
              fi
              echo "Changes pushed"
          else
              echo "Skipping push, check if '$REPO_PATH' exists"
          fi

      fi

      if [ "$flag_garbage_collect" = true ]; then
          if ! nix-collect-garbage; then
              echo "Error running nix-collect-garbage"
              exit 1
          fi
          
          echo "garbage collected"
      fi

      if [ "$flag_optimise" = true ]; then
          if ! nix-store --optimise; then
              echo "Error running nix-store --optimise"
              exit 1
          fi

          echo "nix store optimised"
      fi

      echo "Finished with no errors"
    '';
  };

  dwmkeys = pkgs.writeShellScriptBin "dwmkeys" ''
    echo "Modkey: WINDOWS_KEY"
    echo ""
    echo "Open program                                          q"
    echo "Open terminal                                 shift + q"
    echo ""    
    echo "increase master                                       m"
    echo "decrease master                               shift + m"
    echo "increase mfactor                                      n"
    echo "decrease mfactor                              shift + n"
    echo ""
    echo "Toggle bar                                  shift + tab"
    echo "set master window                                     a"
    echo "switch to last tag                                  tab"
    echo "kill window                                   shift + c"
    echo ""
    echo "next tag ->                                           d"
    echo "next tag <-                                           s"
    echo "next tag and move focused window ->           shift + d"
    echo "next tag and move focused window <-           shift + s"
    echo ""
    echo "increase focused opacity                              b"
    echo "decrease focused opacity                              v"
    echo "increase unfocused opacity                    shift + b"
    echo "decrease unfocused opacity                    shift + v"
    echo ""
    echo "tabbed layout                                         z"
    echo "fullscreen layout                                     x"
    echo "floating layout                                   space"
    echo "toggle window floating                    shift + space"
    echo ""
    echo "change focused monitor ->                            ,"
    echo "change focused monitor <-                    shift + ,"
    echo "change tagged monitor ->                             ."
    echo "change tagged monitor <-                     shift + ."
    echo ""
    echo "select only this tag                               1-9"
    echo "add this tag to selection                control + 1-9"
    echo "assign window to only this tag             shift + 1-9"
    echo "assign window to this tag        control + shift + 1-9"
    echo "select all tags                                      0"
    echo "assign window to all tags                    shift + 0"
  '';

  startup = pkgs.writeShellScriptBin "startup" ''
    export PATH=${pkgs.nix}/bin:/run/current-system/sw/bin:${pkgs.brightnessctl}/bin:$PATH

    ${pkgs.dwmblocks}/bin/dwmblocks &
    ${pkgs.flameshot}/bin/flameshot &
    ${pkgs.sxhkd}/bin/sxhkd &
    ${wallpaper_slideshow}/bin/wallpaper_slideshow "/home/terminator/wallpapers" "20" &
  '';

  prompt = pkgs.writeShellScriptBin "prompt" ''
    [ $(echo -e "No\nYes" | dmenu -fn 'Ubuntu Mono derivative Powerline:size=11' -nb '#FFFFFF' -nf '#000000' -sb '#FFB6FC' -sf '#000000' -i -p "$1") == "Yes" ] && $2
  '';

  run = pkgs.writeShellScriptBin "run" ''
    if [ -z "$1" ]; then
      echo "Usage: $0 <command>"
      exit 1
    fi

    "$@"

    echo "Press any key to continue..."
    read -n 1 -s

    $SHELL
  '';

  wallpaper_slideshow = pkgs.writeShellScriptBin "wallpaper_slideshow" ''
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <directory> <interval>"
        exit 1
    fi

    DIRECTORY="$1"
    INTERVAL="$2"

    if [ ! -d "$DIRECTORY" ]; then
        echo "Error: Directory '$DIRECTORY' does not exist."
        exit 1
    fi

    FILES=($(ls "$DIRECTORY" | grep -E '\.(jpg|png|jpeg)$'))

    if [ ''${#FILES[@]} -eq 0 ]; then
        echo "No image files found in directory '$DIRECTORY'."
        exit 1
    fi

    set_random_wallpaper() {
        local random_file="''${FILES[''$RANDOM % ''${#FILES[@]}]}"
        xwallpaper --zoom "$DIRECTORY/$random_file"
    }

    set_random_wallpaper

    while true; do
        sleep "$INTERVAL"
        set_random_wallpaper
    done
  '';
in
{
  systemd.user.services.startup-script = {
    enable = true;
    description = "startup script";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${startup}/bin/startup";
      RemainAfterExit = true;
    };
  };

  environment.systemPackages = with pkgs; [
    wallpaper_slideshow
    prompt
    run
    dwmkeys
    nixshell
    nixconfig
    nixrebuild
    sb-homesize
    sb-nixstoresize
    sb-config
    sb-brightness
    sb-battery
    sb-datetime
    sb-internet
    sb-ram
    sb-volume
  ];
}
