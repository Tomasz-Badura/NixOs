{ config, pkgs, ... }:
let
  sb-battery = pkgs.writeShellScriptBin "sb-battery" ''
    # Description: Script to get battery status
    source sb-status2d

    for battery in /sys/class/power_supply/BAT?; do
        percent=$(cat "$battery/capacity") 
        status="$(cat "$battery/status")"

        [ "$status" = "Charging" ] && icon_charge="ch"

        printf "%s%s%s %d%%%s" "$s2d_color2" "$icon_charge" "bt" "$percent" "$s2d_reset"
    done && exit 0
  '';

  sb-datetime = pkgs.writeShellScriptBin "sb-datetime" ''
    # Description: Script to get current date and time

    source sb-status2d
    printf "%s%s %s%s" "$s2d_color2" "$(date '+%a, %H:%M')" "$s2d_reset" && exit 0
  '';

  sb-internet = pkgs.writeShellScriptBin "sb-internet" ''
    # Description: Script to get wifi and ethernet status

    source sb-status2d

    show_wname=false
    show_ename=false

    info="$(nmcli dev | grep 'wifi')"
    echo "$info" | grep -wq 'connected' && icon_wifi="conn" || icon_wifi=""
    $show_wname && wname="$(echo "$info" | awk '$1=$2=$3=""; FNR == 1 {print $0};' | sed 's/^ *//g')"

    info="$(nmcli dev | grep 'ethernet')"
    echo "$info" | grep -wq 'connected' && icon_ethr="conn eth" || icon_ethr=""
    $show_ename && ename="$(echo "$info" | awk '$1=$2=$3=""; FNR == 1 {print $0};' | sed 's/^ *//g')"

    printf "%s%s" "$s2d_color1" "$icon_wifi" && $show_wname && printf " %s" "$wname"
    [ -n "$icon_ethr" ] && printf " %s%s" "$s2d_color9" "$icon_ethr" && $show_ename && printf " %s" "$ename"
    printf "%s" "$s2d_reset" && exit 0
  '';

  sb-ram = pkgs.writeShellScriptBin "sb-ram" ''
    # Description: Script to get ram usage

    source sb-status2d

    icon_ram="ram"
    printf "%s%s %s%s" "$s2d_color3" "$icon_ram" "$(free -mh --si | grep '^Mem:' | awk '{print $3}')" "$s2d_reset" && exit 0
  '';

  sb-status2d = pkgs.writeShellScriptBin "sb-status2d" ''
    # Description: Script to configure status2d related content
    enable_status2d=true
    $enable_status2d || return 0

    # use Xresources colors
    enable_Xresources=true

    # status2d colors
    s2d_reset="^d^"
    s2d_color0="^c#2C323C^"
    s2d_color8="^c#3E4452^"
    s2d_color1="^c#E06C75^"
    s2d_color9="^c#E06C75^"
    s2d_color2="^c#98C379^"
    s2d_color10="^c#98C379^"
    s2d_color3="^c#E5C07B^"
    s2d_color11="^c#E5C07B^"
    s2d_color4="^c#61AFEF^"
    s2d_color12="^c#61AFEF^"
    s2d_color5="^c#C678DD^"
    s2d_color13="^c#C678DD^"
    s2d_color6="^c#56B6C2^"
    s2d_color14="^c#56B6C2^"
    s2d_color7="^c#5C6370^"
    s2d_color15="^c#ABB2BF^"

    if [ "$enable_Xresources" = true ]; then
        for i in {0..15}; do
            colorX="$(xrdb -get color'''$'''{i})"
            [ -n "$colorX" ] && eval "s2d_color'''$'''{i}=^c'''$'''{colorX}^"
        done
        unset colorX
    fi
  '';

  sb-volume = pkgs.writeShellScriptBin "sb-volume" ''
    # Description: Script to get current volume
    source sb-status2d

    info="$(amixer get Master | grep '%' | head -n1)"
    percent="$(echo "$info" | sed -E 's/.*\[(.*)%\].*/\1/')"

    printf "%s%s %s%%%s" "$s2d_color3" "vol" "$percent" "$s2d_reset" && exit 0
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

    if ! sudo cp -r /config/* "$REPO_PATH"; then
        echo "Error copying files to $REPO_PATH"
        exit 1
    fi

    cd "$REPO_PATH" || { echo "Error changing directory to $REPO_PATH"; exit 1; }

    if ! git add .; then
        echo "Error adding files to git"
        exit 1
    fi

    NIXOS_GENERATION=$(nixos-version | awk '{print $2}')

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

in
{
  environment.systemPackages = with pkgs; [
    nixconfig
    sb-status2d
    sb-battery
    sb-datetime
    sb-internet
    sb-ram
    sb-volume
  ];
}