#!/bin/dash

# ^c$var^ = fg color
# ^b$var^ = bg color

interval=0

# load colors
. /etc/xdg/chadwm/scripts/bar_themes/dracula

cpu() {
  #cpu_val=$(grep -o "^[^ ]*" /proc/loadavg) # load average
  cpu_val=$(top -bn1 | grep 'Cpu(s)' | awk '{ print 100-$8"%"}') # %
  printf "^c$green^ ^b$grey^  "
  printf "^c$blue^ ^b$grey^ $cpu_val ^b$black^"
}

pkg_updates() {
    updates=$({ timeout 20 xbps-install -unM 2>/dev/null || true; } | wc -l) # void
  # updates=$({ timeout 20 checkupdates 2>/dev/null || true; } | wc -l) # arch
  # updates=$({ timeout 20 aptitude search '~U' 2>/dev/null || true; } | wc -l)  # apt (ubuntu, debian etc)

  if [ -z "$updates" ]; then
    printf "  ^c$green^    Fully Updated"
  else
    printf "  ^c$blue^ ^b$grey^   $updates"" updates"
  fi
}

weather() {
  val="$(curl wttr.in/?format=1 | awk '{ print $2 }')"
  printf "^b$black^ ^c$white^  "
  printf "^c$blue^ ^b$grey^ $val $val2 ^b$black^"
} 

keymap() {
  val="$(setxkbmap -query | awk '/^layout/ { print $2 $3 }' | sed s/i//g)"
  val2="$(setxkbmap -query | awk '/^variant/ { print $2 $3 }' | sed s/i//g)"
  printf "^b$black^ ^c$white^ "
  printf "^c$blue^ ^b$grey^ $val $val2 ^b$black^"
}

bat() {
    # Example acpi -b:
    # Battery 0: Discharging, 53%, 02:31:12 remaining
    # Battery 0: Charging, 82%, 00:25:10 until charged
    local line status percent time state

    line=$(acpi -b 2>/dev/null | head -n1)
    [ -z "$line" ] && { printf "Battery: ??%% (--) --:--"; return; }

    status=$(printf '%s\n' "$line" | awk -F': ' '{print $2}' | cut -d',' -f1)
    percent=$(printf '%s\n' "$line" | grep -o '[0-9]\+%' | head -n1)
    time=$(printf '%s\n' "$line" | grep -o '[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' | head -n1)

    # Normalize state label
    case "$status" in
        *Charging*)    state="+++" ;;
        *Discharging*) state="Remaining" ;;
        *Full*)        state="Full" ;;
        *)             state="$status" ;;
    esac

    [ -z "$time" ] && time="--:--"

    printf "^b$black^ ^c$green^  "
    printf "^c$blue^ ^b$grey^ %s %s %s" "$percent" "($state)" "$time ^b$black^"
}

brightness() {
  printf "^c$red^   "
  printf "^c$red^%.0f\n" $(cat /sys/class/backlight/*/brightness)
}

mem() {
  printf "^b$black^ ^c$green^  "
  printf "^c$blue^ ^b$grey^ $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
}

wlan() {
	case "$(cat /sys/class/net/wl*/operstate 2>/dev/null)" in
	up) printf "^b$black^ ^c$green^ 󰤨 ^d^%s" " ^c$green^Connected" ;;
	down) printf "^b$black^ ^c$red^ 󰤭 ^d^%s" " ^c$red^Disconnected" ;;
	esac
}

clock() {
	printf "^c$black^ ^b$darkblue^ 󱑆 "
	printf "^c$black^^b$blue^ $(date '+%H:%M') "
}

while true; do

  [ $interval = 0 ] || [ $(($interval % 3600)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name "$updates $(keymap) $(weather) $(cpu)% $(mem) $(bat) $(wlan) $(clock)"
done
