#!/bin/sh

while :; do
    # Volume (ALSA)
    vol=$(amixer get Master 2>/dev/null | grep -o "[0-9]*%" | head -1 | tr -d '%')
    [ -n "$vol" ] || vol="--"

    # Network (SSID or interface)
    if nmcli -t -f TYPE,STATE connection show --active 2>/dev/null | grep -q "wireless"; then
        # If connected to Wi-Fi, show SSID
        net="WiFi: $(nmcli -t -f NAME connection show --active 2>/dev/null | grep -m1 "" | cut -d':' -f2)"
    elif nmcli -t -f TYPE,STATE connection show --active 2>/dev/null | grep -q "ethernet"; then
        # If wired, show interface
        net="Wired: $(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')"
    else
        # If not connected
        net="not connected"
    fi

    # Battery (any available battery)
    bat=$(for bat_path in /sys/class/power_supply/BAT*; do
              [ -f "$bat_path/capacity" ] && cat "$bat_path/capacity" && break
          done)
    [ -n "$bat" ] || bat="--"

    # CPU (usage %)
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')
    [ -n "$cpu" ] || cpu="--"

    # Memory (usage %)
    mem=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2*100}')
    [ -n "$mem" ] || mem="--"

    # Date & Hour
    time=$(date '+%a %d %b %H:%M')

    # Output
    echo "VOL $vol% | NET $net | BAT $bat% | CPU $cpu% | MEM $mem% | $time"
    sleep 5
done
