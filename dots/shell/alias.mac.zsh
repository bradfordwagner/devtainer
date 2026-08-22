alias ih='reattach-to-user-namespace idea .'

alias colima_start='colima start --vm-type=vz --vz-rosetta --cpu 2 --memory 2 --disk 50'

# host-side CPU/RAM the Colima VM is costing macOS (human-readable + percentages,
# both of the whole machine and of the VM's configured allocation)
function _colima_stats_once() {
  local pids=(${(f)"$(pgrep -f 'limactl.*colima')"})
  if (( ${#pids} == 0 )); then
    print "colima: not running (no limactl process found)"
    return 1
  fi
  local ncpu=$(sysctl -n hw.ncpu)
  local total_kb=$(( $(sysctl -n hw.memsize) / 1024 ))
  # sum %cpu (relative to one core) and rss(KB) across all colima host procs
  local stats=$(ps -o %cpu=,rss= -p ${(j:,:)pids} | awk '{c+=$1; r+=$2} END{printf "%s %s", c+0, r+0}')
  local cpu=${stats% *} rss_kb=${stats#* }
  local cpu_pct=$(awk -v c=$cpu -v n=$ncpu 'BEGIN{printf "%.1f", c/n}')
  local rss_h=$(awk -v r=$rss_kb 'BEGIN{ if(r>=1048576) printf "%.2f GB", r/1048576; else printf "%.0f MB", r/1024 }')
  local ram_pct=$(awk -v r=$rss_kb -v t=$total_kb 'BEGIN{printf "%.1f", r/t*100}')
  local total_h=$(awk -v t=$total_kb 'BEGIN{printf "%.0f GB", t/1048576}')
  # allocation the VM was started with (colima --cpu / --memory)
  local alloc=$(colima list --json 2>/dev/null | awk -F'[:,]' '{for(i=1;i<=NF;i++){if($i~/"cpus"/)c=$(i+1); if($i~/"memory"/)m=$(i+1)}} END{printf "%s %s", c+0, m+0}')
  local acpu=${alloc% *} amem_bytes=${alloc#* }
  print "colima host usage (${#pids} procs):"
  if (( acpu > 0 )); then
    local cpu_alloc_pct=$(awk -v c=$cpu -v a=$acpu 'BEGIN{printf "%.1f", c/a}')
    local ram_alloc_pct=$(awk -v r=$rss_kb -v a=$amem_bytes 'BEGIN{printf "%.1f", r/(a/1024)*100}')
    local amem_h=$(awk -v a=$amem_bytes 'BEGIN{printf "%.0f GB", a/1073741824}')
    printf ' \tUSAGE\t%% OF MACHINE\t%% OF ALLOCATION\nCPU\t%s%%\t%s%% of %d cores\t%s%% of %d-core alloc\nRAM\t%s\t%s%% of %s\t%s%% of %s alloc\n' \
      "$cpu" "$cpu_pct" "$ncpu" "$cpu_alloc_pct" "$acpu" \
      "$rss_h" "$ram_pct" "$total_h" "$ram_alloc_pct" "$amem_h" \
      | column -t -s $'\t' | sed 's/^/  /'
  else
    printf ' \tUSAGE\t%% OF MACHINE\nCPU\t%s%%\t%s%% of %d cores\nRAM\t%s\t%s%% of %s\n' \
      "$cpu" "$cpu_pct" "$ncpu" "$rss_h" "$ram_pct" "$total_h" \
      | column -t -s $'\t' | sed 's/^/  /'
  fi
}

# colima_stats [-m [interval]] — one-shot, or -m to monitor (default 1s, ctrl-c to exit)
function colima_stats() {
  if [[ $1 == -m ]]; then
    local interval=${2:-1}
    while true; do
      clear
      print "colima_stats -m  (every ${interval}s · ctrl-c to exit · $(date '+%H:%M:%S'))"
      _colima_stats_once || break
      sleep $interval
    done
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
