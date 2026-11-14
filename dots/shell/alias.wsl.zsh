# WSL helpers that drive the Windows host via powercfg.exe / reg.exe / powershell.exe.

# Active-plan AC value of a powercfg setting, in minutes (0 = never).
function _win_power_minutes() {
  local hex
  hex=$(powercfg.exe /q SCHEME_CURRENT "${1}" "${2}" | tr -d '\r' \
    | awk '/Current AC Power Setting Index/ {print $NF}')
  [ -n "${hex}" ] && echo $((hex / 60))
}

function _win_ss_get() {
  reg.exe query 'HKCU\Control Panel\Desktop' /v "${1}" 2>/dev/null | tr -d '\r' \
    | awk -v n="${1}" '$1 == n {print $3}'
}

function _win_ss_set() {
  reg.exe add 'HKCU\Control Panel\Desktop' /v "${1}" /t REG_SZ /d "${2}" /f >/dev/null
}

# Apply a screen saver SystemParametersInfo change to the live session (no re-login).
# 0x000F = SPI_SETSCREENSAVETIMEOUT, 0x0011 = SPI_SETSCREENSAVEACTIVE; 3 = persist + broadcast.
function _win_spi() {
  powershell.exe -NoProfile -Command - >/dev/null <<EOF
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
[W.U]::SystemParametersInfo(${1}, ${2}, [IntPtr]::Zero, 3)
EOF
}

# win_sleep_control [screen_saver_min] [off_min]
# Shows current values (minutes, 0 = never). With args, applies them and leaves missing
# ones unchanged; with no args, prompts for each. Enter or "-" keeps current. off_min sets
# both display off and sleep, on AC and battery of the active power plan. No admin needed. Keep screen saver below
# display off or it never shows. A blank screen saver is set when none is configured.
function win_sleep_control() {
  local ss_new="${1}" ds_new="${2}" ss_cur ds_cur sl_cur ss_active ss_secs
  ss_active=$(_win_ss_get ScreenSaveActive)
  ss_secs=$(_win_ss_get ScreenSaveTimeOut)
  if [ "${ss_active}" = "0" ]; then ss_cur=0
  elif [ -z "${ss_secs}" ]; then ss_cur="unset"
  else ss_cur=$((ss_secs / 60)); fi
  ds_cur=$(_win_power_minutes SUB_VIDEO VIDEOIDLE)
  sl_cur=$(_win_power_minutes SUB_SLEEP STANDBYIDLE)
  echo "Current: screen saver ${ss_cur} min, display off ${ds_cur} min, sleep ${sl_cur} min (0 = never)"

  if [ $# -eq 0 ]; then
    read "ss_new?Screen saver idle minutes [Enter keeps ${ss_cur}]: "
    read "ds_new?Display off + sleep minutes [Enter keeps ${ds_cur}/${sl_cur}]: "
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
    if [ "${ss_new}" -eq 0 ]; then
      _win_ss_set ScreenSaveActive 0 && _win_spi 0x0011 0
    else
      [ -z "$(_win_ss_get SCRNSAVE.EXE)" ] && _win_ss_set SCRNSAVE.EXE 'C:\Windows\System32\scrnsave.scr'
      _win_ss_set ScreenSaveActive 1 && _win_ss_set ScreenSaveTimeOut $((ss_new * 60)) \
        && _win_spi 0x0011 1 && _win_spi 0x000F $((ss_new * 60))
    fi && echo "Screen saver idle: ${ss_cur} -> ${ss_new} min"
    ss_cur="${ss_new}"
  fi

  if [ -z "${ds_new}" ]; then
    echo "Display off: ${ds_cur} min (unchanged)"
  elif [ "${ds_new}" = "${ds_cur}" ]; then
    echo "Display off: already ${ds_cur} min (unchanged)"
  else
    powercfg.exe /change monitor-timeout-ac "${ds_new}" && powercfg.exe /change monitor-timeout-dc "${ds_new}" \
      && echo "Display off: ${ds_cur} -> ${ds_new} min"
    ds_cur="${ds_new}"
  fi

  if [ -z "${ds_new}" ]; then
    echo "Sleep: ${sl_cur} min (unchanged)"
  elif [ "${ds_new}" = "${sl_cur}" ]; then
    echo "Sleep: already ${sl_cur} min (unchanged)"
  else
    powercfg.exe /change standby-timeout-ac "${ds_new}" && powercfg.exe /change standby-timeout-dc "${ds_new}" \
      && echo "Sleep: ${sl_cur} -> ${ds_new} min"
  fi

  if [ "${ss_cur}" != "unset" ] && [ "${ss_cur}" -gt 0 ] && [ "${ds_cur}" -gt 0 ] \
    && [ "${ss_cur}" -ge "${ds_cur}" ]; then
    echo "Warning: screen saver (${ss_cur}) >= display off (${ds_cur}); screen saver never shows." >&2
  fi
}
