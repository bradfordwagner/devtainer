alias ih='reattach-to-user-namespace idea .'

alias colima_start='colima start --vm-type=vz --vz-rosetta --cpu 9 --memory 32 --disk 100'

# actual CPU/RAM the Colima workload is using, sampled INSIDE the guest VM.
# (host-side `ps rss` can't see vz guest memory — it lives in the kernel's
#  Virtualization.framework, not the limactl process — so we sample the guest.)
function _colima_stats_once() {
  colima status >/dev/null 2>&1 || { print "colima: not running"; return 1; }
  local ncpu=$(sysctl -n hw.ncpu) hostmem=$(sysctl -n hw.memsize)
  local hostdisk=$(df -Pk / | awk 'NR==2{print $2*1024}')
  # allocation the VM was started with (colima --cpu / --memory / --disk)
  local alloc=$(colima list --json 2>/dev/null | awk -F'[:,]' '{for(i=1;i<=NF;i++){if($i~/"cpus"/)c=$(i+1); if($i~/"memory"/)m=$(i+1); if($i~/"disk"/)d=$(i+1)}} END{printf "%s %s %s", c+0, m+0, d+0}')
  local acpu=${alloc%% *} arest=${alloc#* }
  local amem=${arest%% *} adisk=${arest#* }
  # sample the guest: two /proc/stat snapshots for CPU%, memory in bytes, and the
  # colima data disk (/dev/vdb1 → /mnt/lima-colima, where Docker's data lives)
  local g=$(colima ssh -- sh -c 'head -1 /proc/stat; sleep 0.4; head -1 /proc/stat; free -b | grep "^Mem:"; df -PB1 /mnt/lima-colima' 2>/dev/null)
  [[ -z $g ]] && { print "colima: could not sample guest"; return 1; }
  print "colima usage (inside the VM):"
  echo "$g" | awk -v acpu=$acpu -v amem=$amem -v adisk=$adisk -v hostmem=$hostmem -v hostdisk=$hostdisk -v ncpu=$ncpu '
    NR==1 { i1=$5; for(i=2;i<=NF;i++)t1+=$i }
    NR==2 { i2=$5; for(i=2;i<=NF;i++)t2+=$i }
    /^Mem:/ { mused=$3 }
    $NF=="/mnt/lima-colima" { dused=$3 }
    END {
      dt=t2-t1; di=i2-i1; bf=(dt>0)?(1-di/dt):0; cores=bf*acpu;
      printf " \tUSAGE\t%% OF ALLOCATION\t%% OF MACHINE\n";
      printf "CPU\t%.2f cores\t%.0f%% of %d cores\t%.1f%% of %d cores\n", cores, bf*100, acpu, cores/ncpu*100, ncpu;
      printf "RAM\t%.2f GB\t%.0f%% of %.0f GB\t%.1f%% of %.0f GB\n", mused/1073741824, mused/amem*100, amem/1073741824, mused/hostmem*100, hostmem/1073741824;
      printf "DISK\t%.2f GB\t%.0f%% of %.0f GB\t%.1f%% of %.0f GB\n", dused/1073741824, dused/adisk*100, adisk/1073741824, dused/hostdisk*100, hostdisk/1073741824;
    }' | column -t -s $'\t' | sed 's/^/  /'
}

# colima_stats [-m [interval]] — one-shot, or -m to monitor (default 1s, ctrl-c to exit)
function colima_stats() {
  if [[ $1 == -m ]]; then
    local interval=${2:-1}
    tput civis 2>/dev/null                       # hide cursor
    trap 'tput cnorm 2>/dev/null; return' INT     # restore cursor on ctrl-c
    clear
    while true; do
      # build the whole frame first (the slow ssh sample happens here, while the
      # previous frame stays on screen), then repaint in place — no blank flicker
      local frame="colima_stats -m  (every ${interval}s · ctrl-c to exit · $(date '+%H:%M:%S'))
$(_colima_stats_once)"
      tput cup 0 0 2>/dev/null                    # cursor home (no screen wipe)
      print -r -- "$frame"
      tput ed 2>/dev/null                          # clear from cursor to end
      sleep $interval
    done
    tput cnorm 2>/dev/null
    return
  fi
  _colima_stats_once
}

function mac_toggle_menubar() {
  osascript <<END
tell application "System Events"
	tell dock preferences to set autohide menu bar to not autohide menu bar
end tell
END
}

# mac_sleep_control [screen_saver_min] [display_sleep_min]
# Shows both current values (minutes, 0 = never). Each arg given is applied directly;
# each arg missing is prompted. Enter or "-" keeps current. Screen saver needs no sudo;
# display sleep uses sudo pmset. Keep screen saver below display sleep or it never shows.
function mac_sleep_control() {
  local ss_new="${1}" ds_new="${2}" ss_secs ss_cur ds_cur
  ss_secs=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null)
  if [ -z "${ss_secs}" ]; then ss_cur="unset"; else ss_cur=$((ss_secs / 60)); fi
  ds_cur=$(pmset -g | awk '/displaysleep/ {print $2}')
  echo "Current: screen saver ${ss_cur} min, display sleep ${ds_cur} min (0 = never)"

  if [ -z "${ss_new}" ]; then
    read "ss_new?Screen saver idle minutes [Enter keeps ${ss_cur}]: "
  fi
  if [ -z "${ds_new}" ]; then
    read "ds_new?Display sleep minutes [Enter keeps ${ds_cur}]: "
  fi

  local v
  for v in "${ss_new}" "${ds_new}"; do
    case "${v}" in
      ""|"-") ;;
      *[!0-9]*) echo "Error: minutes must be an integer: ${v}" >&2; return 1 ;;
    esac
  done
  [ "${ss_new}" = "-" ] && ss_new=""
  [ "${ds_new}" = "-" ] && ds_new=""

  if [ -z "${ss_new}" ]; then
    echo "Screen saver idle: ${ss_cur} min (unchanged)"
  elif [ "${ss_new}" = "${ss_cur}" ]; then
    echo "Screen saver idle: already ${ss_cur} min (unchanged)"
  else
    defaults -currentHost write com.apple.screensaver idleTime -int $((ss_new * 60)) \
      && killall cfprefsd \
      && echo "Screen saver idle: ${ss_cur} -> ${ss_new} min"
    ss_cur="${ss_new}"
  fi
  if [ -z "${ds_new}" ]; then
    echo "Display sleep: ${ds_cur} min (unchanged)"
  elif [ "${ds_new}" = "${ds_cur}" ]; then
    echo "Display sleep: already ${ds_cur} min (unchanged)"
  else
    sudo pmset -a displaysleep "${ds_new}" && echo "Display sleep: ${ds_cur} -> ${ds_new} min"
    ds_cur="${ds_new}"
  fi

  if [ "${ss_cur}" != "unset" ] && [ "${ss_cur}" -gt 0 ] && [ "${ds_cur}" -gt 0 ] \
    && [ "${ss_cur}" -ge "${ds_cur}" ]; then
    echo "Warning: screen saver (${ss_cur}) >= display sleep (${ds_cur}); screen saver never shows." >&2
  fi
}

function mac_trust_certificate() {
  certificate_file=${1}

  if [ ! -f "$certificate_file" ]; then
    echo "Error: Certificate file not found: $certificate_file" >&2
    return 1
  fi

  # Create temp directory for splitting certificates
  TMP_DIR=$(mktemp -d /tmp/mac_trust_certs.XXXXXX)

  # Split certificate file into individual certificates
  awk -v tmpdir="$TMP_DIR" '
    /BEGIN CERTIFICATE/ {
      cert_count++
      outfile = tmpdir "/cert_" cert_count ".pem"
    }
    {
      if (cert_count > 0) {
        print > outfile
      }
    }
  ' "$certificate_file"

  # Trust each certificate
  cert_num=0
  for cert in "$TMP_DIR"/cert_*.pem; do
    if [ -f "$cert" ]; then
      cert_num=$((cert_num + 1))
      echo "Trusting certificate #${cert_num}..."
      sudo security add-trusted-cert \
        -d \
        -r trustRoot \
        -k /Library/Keychains/System.keychain \
        "$cert"
    fi
  done

  # Cleanup
  rm -rf "$TMP_DIR"

  echo "Successfully trusted ${cert_num} certificate(s)"
}
