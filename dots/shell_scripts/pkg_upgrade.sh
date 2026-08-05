#!/bin/bash
# Updates + upgrades every package manager present on this machine (brew, apt)
# and prints one summary of what actually changed, grouped by manager.
#
# Upgraded vs skipped is derived by diffing each manager's outdated list before
# and after the upgrade, so packages that are held back (apt) or fail to build
# (brew) are reported as skipped rather than silently counted as upgraded.

set -uo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT

managers=""
: > "${tmp}/report.tsv"

################################################
# outdated listings -> name<TAB>installed<TAB>available
################################################

# brew outdated --verbose emits "name (1.0) < 2.0" for formulae and
# "name (1.0) != 2.0" for casks.
brew_outdated() {
  brew outdated --verbose 2>/dev/null |
    sed -E 's/^([^ ]+) \((.+)\) (<|!=) (.+)$/\1\t\2\t\4/' |
    awk -F'\t' 'NF==3'
}

# apt list --upgradable emits "name/repo 2.0 amd64 [upgradable from: 1.0]".
apt_outdated() {
  apt list --upgradable 2>/dev/null |
    sed -E 's#^([^/]+)/[^ ]+ ([^ ]+) [^ ]+ \[upgradable from: ([^]]+)\]#\1\t\3\t\2#' |
    awk -F'\t' 'NF==3'
}

################################################
# upgrades
################################################

run_brew() {
  command -v brew > /dev/null 2>&1 || return 0
  managers="${managers} brew"

  echo "${palette_blue}==> brew update${palette_restore}"
  brew update

  brew_outdated > "${tmp}/brew.before"
  if [[ ! -s ${tmp}/brew.before ]]; then
    echo "${palette_lightgray}    brew is already up to date${palette_restore}"
    return 0
  fi

  echo "${palette_blue}==> brew upgrade ($(wc -l < "${tmp}/brew.before" | tr -d ' ') outdated)${palette_restore}"
  brew upgrade
  brew_outdated | cut -f1 > "${tmp}/brew.after"
}

run_apt() {
  command -v apt-get > /dev/null 2>&1 || return 0
  managers="${managers} apt"

  echo "${palette_blue}==> apt-get update${palette_restore}"
  sudo apt-get update -qq

  apt_outdated > "${tmp}/apt.before"
  if [[ ! -s ${tmp}/apt.before ]]; then
    echo "${palette_lightgray}    apt is already up to date${palette_restore}"
    return 0
  fi

  echo "${palette_blue}==> apt-get upgrade ($(wc -l < "${tmp}/apt.before" | tr -d ' ') outdated)${palette_restore}"
  sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get upgrade -y
  apt_outdated | cut -f1 > "${tmp}/apt.after"
}

################################################
# reporting
################################################

# anything still outdated after the upgrade was skipped; everything else moved.
classify() {
  local mgr=$1
  local before="${tmp}/${mgr}.before" after="${tmp}/${mgr}.after"
  [[ -s ${before} ]] || return 0
  touch "${after}"

  local name old new
  while IFS=$'\t' read -r name old new; do
    [[ -n ${name} ]] || continue
    if grep -qxF "${name}" "${after}"; then
      printf 'skip\t%s\t%s\t%s\t%s\n' "${mgr}" "${name}" "${old}" "${new}"
    else
      printf 'up\t%s\t%s\t%s\t%s\n' "${mgr}" "${name}" "${old}" "${new}"
    fi
  done < "${before}" >> "${tmp}/report.tsv"
}

summary() {
  awk -F'\t' \
    -v order="${managers}" \
    -v c_head="${palette_lgreen:-}" \
    -v c_mgr="${palette_lyellow:-}" \
    -v c_name="${palette_cyan:-}" \
    -v c_old="${palette_lightgray:-}" \
    -v c_skip="${palette_red:-}" \
    -v c_off="${palette_restore:-}" '
    {
      mgr = $2
      # widths are per manager so short brew names are not padded out to the
      # width of a long apt package name
      if (length($3) > w_name[mgr]) w_name[mgr] = length($3)
      if (length($4) > w_old[mgr])  w_old[mgr]  = length($4)
      if ($1 == "up") {
        i = ++up_n[mgr]; up[mgr, i] = $3 "\t" $4 "\t" $5; total++
      } else {
        i = ++sk_n[mgr]; sk[mgr, i] = $3 "\t" $4 "\t" $5; skipped++
      }
    }
    END {
      printf "\n%s──── upgrade summary ────%s\n", c_head, c_off

      n = split(order, mgrs, " ")
      for (m = 1; m <= n; m++) {
        mgr = mgrs[m]
        count = up_n[mgr] + 0
        printf "%s%-5s%s %d upgraded\n", c_mgr, mgr, c_off, count
        for (i = 1; i <= count; i++) {
          split(up[mgr, i], f, "\t")
          printf "  %s%-*s%s %s%-*s%s → %s\n",
            c_name, w_name[mgr], f[1], c_off, c_old, w_old[mgr], f[2], c_off, f[3]
        }
        for (i = 1; i <= sk_n[mgr] + 0; i++) {
          split(sk[mgr, i], f, "\t")
          printf "  %s%-*s%s still outdated (%s → %s)\n",
            c_skip, w_name[mgr], f[1], c_off, f[2], f[3]
        }
      }

      printf "%stotal%s %d upgraded", c_mgr, c_off, total + 0
      if (skipped + 0 > 0) printf ", %d skipped", skipped
      printf "\n"
    }
  ' "${tmp}/report.tsv"
}

################################################

run_brew
run_apt

for mgr in ${managers}; do
  classify "${mgr}"
done
summary
