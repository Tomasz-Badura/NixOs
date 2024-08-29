{ config, pkgs, ... }:
let
  sb-battery = pkgs.writeShellScriptBin "sb-battery" ''
    # Description: Script to get battery status

    source sb-colors

    for battery in /sys/class/power_supply/BAT?; do
        percent=$(cat "$battery/capacity") 
        status="$(cat "$battery/status")"

        [ "$status" = "Charging" ] && icon_charge="ch"

        printf "%s%s%s %d%%%s" "$accent_color" "$icon_charge" "bt" "$text_color" "$percent" "$reset_color"
    done && exit 0
  '';

  sb-datetime = pkgs.writeShellScriptBin "sb-datetime" ''
      # Description: Script to get current date and time

      source sb-colors

      case $BLOCK_BUTTON in
      1) wezterm start -- bash -c "date; exec bash";;
      esac

      printf "%s%s %s%s" "$text_color" "$(date '+%a, %H:%M')" "$reset_color" && exit 0
  '';

  sb-internet = pkgs.writeShellScriptBin "sb-internet" ''
    # Description: Script to get wifi and ethernet status

    source sb-colors

    show_wname=false
    show_ename=false

    info="$(nmcli dev | grep 'wifi')"
    echo "$info" | grep -wq 'connected' && icon_wifi="wifi" || icon_wifi=""
    $show_wname && wname="$(echo "$info" | awk '$1=$2=$3=""; FNR == 1 {print $0};' | sed 's/^ *//g')"

    info="$(nmcli dev | grep 'ethernet')"
    echo "$info" | grep -wq 'connected' && icon_ethr="ethernet" || icon_ethr=""
    $show_ename && ename="$(echo "$info" | awk '$1=$2=$3=""; FNR == 1 {print $0};' | sed 's/^ *//g')"

    printf "%s%s" "$text_color" "$icon_wifi" && $show_wname && printf " %s" "$wname"
    [ -n "$icon_ethr" ] && printf " %s%s" "$icon_ethr" && $show_ename && printf " %s" "$ename"
    printf "%s" "$reset_color" && exit 0
  '';

  sb-ram = pkgs.writeShellScriptBin "sb-ram" ''
      # Description: Script to get ram usage

      source sb-colors
      printf "%s%s %s%s" "$accent_color" "ram" "$text_color" "$(free -mh --si | grep '^Mem:' | awk '{print $3}')" "$reset_color" && exit 0
  '';

  sb-volume = pkgs.writeShellScriptBin "sb-volume" ''
      # Description: Script to get current volume

      source sb-colors

      info="$(amixer get Master | grep '%' | head -n1)"
      percent="$(echo "$info" | sed -E 's/.*\[(.*)%\].*/\1/')"

      printf "%s%s %s%%%s" "$accent_color" "vol" "$text_color" "$percent" "$reset_color" && exit 0
  '';

  sb-colors = pkgs.writeShellScriptBin "sb-colors" ''
    # Description: Script to define color variables for status scripts

    text_color="^c#000000^"  # Black text
    accent_color="^c#FFB6FC^"  # Pink accent
    reset_color="^d^"  # Reset color
  '';

  nixconfig = pkgs.writeShellScriptBin "nixconfig" ''
    if [ -z "$1" ]; then
        echo "Usage: nixconfig <path-to-cloned-repo>"
        exit 1
    fi

    REPO_PATH=$(realpath "$1")

    if ! sudo code --wait /config --user-data-dir --no-sandbox; then
        echo "Error opening VS Code."
        exit 1
    fi
    
    find "$REPO_PATH" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

    if [ $? -ne 0 ]; then
        echo "Error cleaning files in $REPO_PATH"
        exit 1
    fi

    if ! sudo cp -r /config/* "$REPO_PATH"; then
        echo "Error copying files to $REPO_PATH"
        exit 1
    fi

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

    if ! sudo nixos-rebuild switch --flake /config; then
        echo "error rebuilding nixos"
        exit 1
    fi

    if ! home-manager switch --flake /config; then
        echo "Error rebuilding home manager"
        exit 1
    fi

    echo "Configuration successfully updated and committed."
  '';

  nixrebuild = pkgs.writeShellScriptBin "nixrebuild" ''
    flag_home=false
    flag_nixos=false
    flag_commit=""

    while getopts "hnc:" option; do
        case $option in
            h)
                flag_home=true
                ;;
            n)
                flag_nixos=true
                ;;
            c)
                flag_commit=$OPTARG
                ;;
            *)
                echo "Usage: $0 [-h] [-n] [-c value]"
                echo "-h      no home rebuild"
                echo "-n      no nixos rebuild"
                echo "-c      commit changes"
                exit 1
                ;;
        esac
    done

    shift $((OPTIND - 1))
    REPO_PATH=$(realpath "$flag_commit")

    if [ -d "$REPO_PATH" ]; then
        find "$REPO_PATH" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

        if [ $? -ne 0 ]; then
            echo "Error cleaning files in $REPO_PATH"
            exit 1
        fi

        if ! sudo cp -r /config/* "$REPO_PATH"; then
            echo "Error copying files to $REPO_PATH"
            exit 1
        fi

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
    fi

    if [ "$flag_nixos" = false ]; then
        if ! sudo nixos-rebuild switch --flake /config; then
            echo "Error rebuilding NixOS"
            exit 1
        fi
    fi

    if [ "$flag_home" = false ]; then
        if ! home-manager switch --flake /config; then
            echo "Error rebuilding home manager"
            exit 1
        fi
    fi

    echo "Finished"
  '';
in
{
  environment.systemPackages = with pkgs; [
    nixconfig
    nixrebuild
    sb-colors
    sb-battery
    sb-datetime
    sb-internet
    sb-ram
    sb-volume
  ];
}