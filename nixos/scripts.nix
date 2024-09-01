{ config, pkgs, ... }:
let
  sb-battery = pkgs.writeShellScriptBin "sb-battery" ''
    # Description: Script to get battery status

    source sb-colors

    for battery in /sys/class/power_supply/BAT?; do
        percent=$(cat "$battery/capacity") 
        status="$(cat "$battery/status")"

        [ "$status" = "Charging" ] && icon_charge="charging"
        [ "$status" = "Not charging" ] && icon_charge= "idle"

        printf "%s%s%d%s" "$icon_charge" " battery " "$percent" "%"
    done && exit 0
  '';

  sb-datetime = pkgs.writeShellScriptBin "sb-datetime" ''
    # Description: Script to get current date and time

    source sb-colors

    case $BLOCK_BUTTON in # TODO
    1) exec code;;
    esac

    printf "%s" "$(date '+%a, %H:%M')" && exit 0
  '';

  sb-internet = pkgs.writeShellScriptBin "sb-internet" ''
    # Description: Script to get Wi-Fi and Ethernet status
    source sb-colors

    info="$(nmcli dev | grep 'wifi')"

    if echo "$info" | grep -wq 'connected'; then
        icon_wifi="wifi"
    else
        icon_wifi=""
    fi

    info="$(nmcli dev | grep 'ethernet')"

    if echo "$info" | grep -wq 'connected'; then
        icon_ethr="ethernet"
    else
        icon_ethr=""
    fi

    if [ -n "$icon_wifi" ]; then
        printf "$icon_wifi"
    fi

    if [ -n "$icon_ethr" ]; then
        printf "$icon_ethr"
    fi

    exit 0
  '';

  sb-ram = pkgs.writeShellScriptBin "sb-ram" ''
    # Description: Script to get ram usage

    source sb-colors
    printf "%s%s" "ram " "$(free -mh --si | grep '^Mem:' | awk '{print $3}')" && exit 0
  '';

  sb-volume = pkgs.writeShellScriptBin "sb-volume" ''
    # Description: Script to get current volume

    source sb-colors

    percent="$(pulsemixer --get-volume | awk '{print $1}')"
    printf "%s%d%s" "vol " "$percent" "%" && exit 0
  '';

  sb-colors = pkgs.writeShellScriptBin "sb-colors" ''
    # Description: Script to define color variables for status scripts

    text_color="^c#000000^"  # Black text
    accent_color="^c#FFB6FC^"  # Pink accent
    reset_color="^d^"  # Reset color
  '';

  nixconfig = pkgs.writeShellScriptBin "nixconfig" ''
    flag_norebuild=false
    flag_commit=false
    flag_skipconf=false

    while getopts "sfc:" option; do
        case $option in
            s)
                flag_norebuild=true
                ;;
            f)
                flag_skipconf=true
                ;;
            c)
                flag_commit=$OPTARG
                ;;
            *)
                echo "Usage: nixconfig [-s] [-f] [-c value]"
                echo "  -s            don't rebuild"
                echo "  -f            skip rebuild confirmations, rebuild both home-manager and nixos"
                echo "  -c [value]    commit changes, value = path to cloned repo"
                exit 1
                ;;
        esac
    done

    REPO_PATH=$(realpath "$1")

    if ! code --wait /config; then
        echo "Error opening VS Code."
        exit 1
    fi

    if [ -d $REPO_PATH ]; then
        if ! sudo rm -rf "$REPO_PATH"/*; then
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
    fi

    if [ flag_norebuild ]; then
        echo "finished"
        exit 0
    fi

    if $flag_skipconf; then
        if ! sudo nixos-rebuild switch --flake /config; then
            echo "Error rebuilding NixOS"
            exit 1
        fi

        if ! home-manager switch --flake /config; then
            echo "Error rebuilding Home Manager"
            exit 1
        fi
    else
        read -p "Do you want to rebuild NixOS (y/yes to proceed)? " response
        if [[ "$response" == "y" || "$response" == "yes" ]]; then
            if ! sudo nixos-rebuild switch --flake /config; then
                echo "Error rebuilding NixOS"
                exit 1
            fi
        else
            echo "Skipping NixOS rebuild."
        fi

        read -p "Do you want to rebuild Home Manager (y/yes to proceed)? " response
        if [[ "$response" == "y" || "$response" == "yes" ]]; then
            if ! home-manager switch --flake /config; then
                echo "Error rebuilding Home Manager"
                exit 1
            fi
        else
            echo "Skipping Home Manager rebuild."
        fi
    fi

    echo "finished succesfully"
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
                echo "Usage: nixrebuild [-h] [-n] [-c value]"
                echo "  -h            don't rebuild home-manager"
                echo "  -n            don't rebuild nixos"
                echo "  -c [value]    commit changes, value = path to cloned repo"
                exit 1
                ;;
        esac
    done

    shift $((OPTIND - 1))
    REPO_PATH=$(realpath "$flag_commit")

    if [ -d "$REPO_PATH" ]; then
        if ! sudo rm -rf "$REPO_PATH"/*; then
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
    export PATH=${pkgs.nix}/bin:${pkgs.dwmblocks}/bin:${pkgs.dwm}/bin:${pkgs.dwmblocks}/bin:${pkgs.flameshot}/bin:/run/current-system/sw/bin:$PATH
    dwmblocks &
    flameshot &
  '';

  prompt = pkgs.writeShellScriptBin "prompt" ''
    [ $(echo -e "No\nYes" | dmenu -p "$i") == "Yes" ] && $2
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
    prompt
    dwmkeys
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