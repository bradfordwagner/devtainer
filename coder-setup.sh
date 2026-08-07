#!/usr/bin/env bash
#
# Coder workspace bootstrap — full first-time setup for a fresh (or rebuilt) pod.
# The annotated walkthrough lives in coder.md; this script is the runnable version of it.
#
# Run it inside the workspace (coder ssh bwagner) with PROCESS SUBSTITUTION, not a pipe:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/bradfordwagner/devtainer/main/coder-setup.sh)
#
# Why not `curl ... | bash`? A pipe feeds the script in on stdin, leaving `sudo passwd coder`
# (and rofi's setup.sh) with no terminal to read from. Process substitution passes the script
# as a file argument and keeps the tty attached, so the interactive prompts still work.
#
# Deliberately NOT `set -e`: this mirrors pasting the block line-by-line — a non-fatal hiccup
# (e.g. pkill finding nothing to kill) shouldn't abort the whole run.

# --- interactive: give the coder login a password (reads it twice) ---
sudo passwd coder

# --- desktop bits — the pod is bare (no window manager). xrdp/xorgxrdp are usually already
# present. The sway userland (waybar, swaybg, rofi, etc.) is what the dotfiles sway config
# actually drives: without it you get a black screen (no wallpaper/bar) even though sway itself
# launches fine. x11-xserver-utils provides setxkbmap, which the sway config execs on startup.
# NOTE: sway starts at the small resolution pinned in dots/config/sway/config; after connecting,
# bump it to your monitor via dots/shell_scripts/speed/sway_select_display.sh (fzf res/scale picker).
sudo apt update
sudo apt install -y \
  xrdp xorgxrdp xserver-xorg-core dbus-x11 xwayland rsync \
  sway swaybg swayidle swaylock foot rofi waybar fonts-font-awesome \
  grim slurp wl-clipboard brightnessctl x11-xserver-utils psmisc file unzip ghostty \
  zsh

# make zsh the login shell. /etc/passwd is on the wiped layer, so re-run per rebuild;
# passwordless sudo avoids the interactive chsh password prompt.
sudo chsh -s /usr/bin/zsh coder

# xrdp on 3390 (matches the port-forward)
sudo sed -i 's/^port=3389/port=3390/' /etc/xrdp/xrdp.ini

# THE fix: let the xrdp front-end reach the Xorg backend socket.
#   The pod's xrdp daemon runs as group `xrdp`, but sesman defaults the per-session socket
#   dir (/run/xrdp/sockdir/<uid>) to group `root`. The front-end then gets EACCES entering
#   it, and lib_mod_connect retries for 30s before failing with
#   "Error connecting to user session" — even though login + the X backend both succeed.
sudo sed -i -E 's/^[#; ]*SessionSockdirGroup=.*/SessionSockdirGroup=xrdp/' /etc/xrdp/sesman.ini

# session driver = sway. `task bb` (dotfiles) renders this same file via templates/xsession.j2,
# which now carries the identical XDG_RUNTIME_DIR guard below — so `task bb` no longer clobbers
# this fix. Running it here before dotfiles is set up is still harmless. (sway runs fine over
# xrdp once the socket fix above is in; the WM was never the problem.)
#
# The XDG_RUNTIME_DIR guard is NOT optional: without it sway aborts on startup with
# "XDG_RUNTIME_DIR is not set in the environment. Aborting." and the RDP window opens then
# instantly closes (xrdp.log shows a successful lib_mod_connect immediately followed by
# "Xorg server closed connection"). The pod has no systemd / pam_systemd to create
# /run/user/<uid>, so nothing sets XDG_RUNTIME_DIR — we point it at a tmp dir ourselves when
# it's unset. Don't trim this back to a bare `exec sway`.
cat > ~/.xsession <<'EOF'
#!/bin/sh
if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/tmp/xdg-runtime-$(id -u)
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
fi
exec sway
EOF
chmod +x ~/.xsession

# (re)start xrdp — the pod has no systemd, so use `service`, not `systemctl`.
# NOTE: `service xrdp restart` is unreliable here — its PID tracking is broken, so it can
# leave orphan xrdp processes bound to 3390 (new starts then fail with
# "g_tcp_bind ... errno=98 address already in use") and a stale xrdp-sesman.pid that makes
# sesman refuse to start ("xrdp-sesman is already running"). On a fresh workspace a plain
# `service xrdp start` is enough; the full clean start below is safe to always run.
sudo pkill -9 -f xrdp; sleep 2                       # kill any orphan front-ends/sesman
sudo rm -rf /run/xrdp/sockdir/*                      # clear stale (and pre-fix group-root) sockets
sudo rm -f /var/run/xrdp/xrdp-sesman.pid             # clear stale sesman pid
sudo service xrdp start                              # starts both xrdp + sesman
# verify both are up: `ps aux | grep -E 'xrdp|sesman'` should show /usr/sbin/xrdp AND
# /usr/sbin/xrdp-sesman. If sesman is missing, start it directly: `sudo /usr/sbin/xrdp-sesman`

# firefox — Ubuntu's `firefox` .deb is only a stub that launches the firefox SNAP, and snaps
# need snapd → systemd, which the pod doesn't have. So install the real native .deb from
# Mozilla's APT repo instead (pinned so it wins over the stub; --allow-downgrades because the
# stub carries a fake high epoch version). No snap/systemd required.
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
sudo apt-get update -qq
sudo apt-get install -y --allow-downgrades firefox
# verify it's the real thing (not the snap stub): `file /usr/bin/firefox` should be an ELF
# binary / symlink into /usr/lib/firefox, and `firefox --version` should print a version.

# rofi theming — the sway launcher (dots/shell_scripts/rofi_launcher.sh, bound to alt+d) themes
# rofi with catppuccin + type-1/style-5, but only if those .rasi files exist under ~/.config/rofi;
# without them it silently falls back to an unstyled menu. adi1090x's installer populates them.
# This writes to ~/.config/rofi (on the persistent ~/), so it's one-time — not per-rebuild.
rm -rf /tmp/rofi && git clone --depth 1 https://github.com/adi1090x/rofi /tmp/rofi && (cd /tmp/rofi && ./setup.sh)

# nerd font (IosevkaTerm) — the ghostty/alacritty configs default to "IosevkaTerm Nerd Font Mono";
# without it terminals fall back to a glyph-less font (broken powerline/icons). Writes to
# ~/.local/share/fonts (persistent ~/), so one-time — not per-rebuild. Needs unzip (apt block above).
mkdir -p ~/.local/share/fonts && curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip" -o /tmp/IosevkaTerm.zip && unzip -o /tmp/IosevkaTerm.zip -d ~/.local/share/fonts/IosevkaTerm && fc-cache -fv

# ---- homebrew (persistent store on the PV — see the "homebrew" section in coder.md for the why) ----
# keep the blessed prefix string but back its storage with a symlink into the persistent home
# volume (~/ = /home/coder). This one symlink is the only brew bit on the ephemeral layer.
mkdir -p ~/linuxbrew
sudo mkdir -p /home/linuxbrew
sudo ln -sfn ~/linuxbrew /home/linuxbrew/.linuxbrew

# install brew — NONINTERACTIVE=1 stops it waiting on a RETURN prompt so this runs unattended;
# passwordless sudo covers its internal sudo calls. Writes into ~/linuxbrew via the symlink.
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
brew install ansible gh go-task -y

# zap (zsh plugin manager) — install only if missing so re-runs (~/.local/share/zap is on the
# persistent volume) don't hit its interactive "Reinstall Zap? [y/N]" prompt and hang. --keep
# stops it backing up/rewriting ~/.zshrc, which `task bare_bones` links from the dotfiles anyway
# (that .zshrc already sources zap.zsh via this same guard, so only the on-disk files are needed).
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] || \
  zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1 --keep

# clone dotfiles and bring the box up (~/ persists across rebuilds, so clone only if missing,
# then always pull so a persisted checkout picks up upstream changes)
cd && { [ -d dotfiles/.git ] || git clone https://github.com/bradfordwagner/devtainer.git dotfiles; } && cd dotfiles && git pull
task linux_brew_install && task bare_bones
