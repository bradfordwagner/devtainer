# wsl

## linux install XFCE
- https://wsl-ui.octasoft.co.uk/blog/wsl2-ubuntu-desktop-xrdp#step-1-install-your-desktop

```
sudo apt update
sudo apt install xfce4 xfce4-goodies xrdp xclip -y
sudo sed -i 's/^port=3389/port=3390/' /etc/xrdp/xrdp.ini
printf '#!/bin/sh\nstartxfce4\n' > ~/.xsession && chmod +x ~/.xsession
# ^ bootstrap only — once dotfiles are cloned and `task bb` has run, this file is
# overwritten by the Ansible-managed templates/xsession.j2 (`exec sway`), see swaywm section below
grep -q 'systemd=true' /etc/wsl.conf 2>/dev/null || sudo tee -a /etc/wsl.conf << 'EOF'
[boot]
systemd=true
EOF
sudo systemctl enable xrdp --now
```

- connect: `Win+R` → `mstsc` → `localhost:3390`
- if systemd wasn't enabled, restart wsl first from powershell: `wsl --shutdown`

### remove default XFCE shortcuts that conflict with tmux
```
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>l" -r 2>/dev/null || true
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Primary><Alt>l" -r 2>/dev/null || true
```

## coder — remote desktop (RDP)

RDP into the xrdp desktop running in a Coder Kubernetes workspace. Same xrdp/Xorg stack as
the XFCE section above, but the pod is bare (no systemd, no window manager) and ships xrdp
with a broken default, so it needs the extra fixes below.

Forward the workspace's xrdp port (`3390`) to a local port, then point mstsc at it:

```bash
# forward local 5900 -> workspace xrdp on 3390
# (keep the local port off 3390 so a local WSL xrdp on 3390 doesn't clash)
coder port-forward bwagner --tcp 5900:3390
# leave this running; once it prints "Ready!" the tunnel is up
```

- connect: `Win+R` → `mstsc` → `localhost:5900`
- log in as the `coder` user with the password you set in the first setup step below

### first-time setup inside a fresh workspace

Inside the workspace (`coder ssh bwagner`). First the one interactive bit — run it and answer
the prompts (it reads the new password twice, so it can't live in a pasted block):

```bash
sudo passwd coder   # give the coder login a password
```

Then paste the rest in one shot — it's all non-interactive:

```bash
# desktop bits — the pod is bare (no window manager). xrdp/xorgxrdp are usually already present.
sudo apt update
sudo apt install -y xrdp xorgxrdp xserver-xorg-core dbus-x11 sway foot xwayland rsync

# xrdp on 3390 (matches the port-forward)
sudo sed -i 's/^port=3389/port=3390/' /etc/xrdp/xrdp.ini

# THE fix: let the xrdp front-end reach the Xorg backend socket.
#   The pod's xrdp daemon runs as group `xrdp`, but sesman defaults the per-session socket
#   dir (/run/xrdp/sockdir/<uid>) to group `root`. The front-end then gets EACCES entering
#   it, and lib_mod_connect retries for 30s before failing with
#   "Error connecting to user session" — even though login + the X backend both succeed.
sudo sed -i -E 's/^[#; ]*SessionSockdirGroup=.*/SessionSockdirGroup=xrdp/' /etc/xrdp/sesman.ini

# session driver = sway. `task bb` (dotfiles) renders this same file via templates/xsession.j2,
# so it's only needed before dotfiles is set up — harmless to run either way. (sway runs fine
# over xrdp once the socket fix above is in; the WM was never the problem.)
#
# The XDG_RUNTIME_DIR export is NOT optional: without it sway aborts on startup with
# "XDG_RUNTIME_DIR is not set in the environment. Aborting." and the RDP window opens then
# instantly closes. The pod has no systemd / pam_systemd to create /run/user/<uid>, so nothing
# sets XDG_RUNTIME_DIR — we point it at a tmp dir ourselves. Don't trim this back to `exec sway`.
cat > ~/.xsession <<'EOF'
#!/bin/sh
export XDG_RUNTIME_DIR=/tmp/xdg-runtime-$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
exec sway
EOF
chmod +x ~/.xsession

# (re)start xrdp — the pod has no systemd, so use `service`, not `systemctl`
sudo rm -rf /run/xrdp/sockdir/*   # clear any stale group-root sockdir from before the fix
sudo service xrdp restart
```

Then reconnect via mstsc. Verify the fix landed: `/run/xrdp/sockdir/1000` should be group
`xrdp`, and `/var/log/xrdp.log` should show `lib_mod_connect` followed immediately by
`lib_mod_log_peer: ... connected to Xorg_pid=...` (no 30-second gap).

> [!NOTE]
> The pod has no systemd (`systemctl` is likely absent) — start/restart xrdp with
> `sudo service xrdp start` / `restart`, not `systemctl`.

> [!CAUTION]
> A Coder pod's writable layer is wiped on rebuild, so all of the above (the `sesman.ini`
> fix and the installed packages especially) vanishes and must be re-run. The durable home
> for the package installs and config edits is the workspace's base container image / template —
> bake them in there so every workspace comes up RDP-ready.

## homebrew
```
sudo apt update && sudo apt upgrade -y
sudo apt-get install build-essential procps curl file git -y
sudo apt install zsh ghostty alacritty firefox -y
chsh -s /usr/bin/zsh
sudo apt install sway swaybg swayidle swaylock foot rofi waybar fonts-font-awesome grim slurp wl-clipboard xwayland -y

# rofi themes
cd /tmp && git clone https://github.com/adi1090x/rofi && cd rofi && ./setup.sh

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
cd /home/linuxbrew/.linuxbrew/bin
./brew install ansible gh go-task -y

# zap
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1

cd && git clone https://github.com/bradfordwagner/devtainer.git dotfiles && cd dotfiles
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
task linux_brew_install && task bare_bones

```

## passwordless sudo
From Windows Terminal / PowerShell, open WSL as root, then add a sudoers entry:
```
wsl -u root
echo 'bw ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/bw
chmod 440 /etc/sudoers.d/bw
```

## troubleshooting

### nvim
- `<space>f` or other keybindings not working: telescope-fzf-native may need recompiling
  ```
  cd ~/.local/share/nvim/lazy/telescope-fzf-native.nvim && make
  ```
  Or from inside nvim: `:Lazy build telescope-fzf-native.nvim`

## swaywm
- https://github.com/bmo1177/sway_setup
- cheatsheet - https://wiki.garudalinux.org/en/sway-cheatsheet
- sway replaces XFCE as the session entirely rather than running nested inside it.
  `~/.xsession` is Ansible-managed (`templates/xsession.j2` → `tasks/jinga-templates.yml`,
  Linux-only) and just does `exec sway` — no more toggling xfwm4/xfce-panel/xfce4-power-manager
  through the XFCE session-and-startup GUI.
  - xrdp still provides the underlying X11 display (WSL2 has no DRM/GPU seat), so sway runs
    against sway's X11 backend automatically since `DISPLAY` is set — it's just no longer
    nested inside a running XFCE desktop.
  - after cloning dotfiles and running `task bb` (which renders this template), reconnect via
    mstsc — the next xrdp login launches sway directly instead of XFCE.
  - if you ever need XFCE back (e.g. to debug something outside sway), temporarily replace
    `~/.xsession` with `startxfce4` and reconnect; re-running `task bb` restores `exec sway`.

## fonts
```
mkdir -p ~/.local/share/fonts && curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip" -o /tmp/IosevkaTerm.zip && unzip -o /tmp/IosevkaTerm.zip -d ~/.local/share/fonts/IosevkaTerm && fc-cache -fv
```

## docker
- https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
- post install: https://docs.docker.com/engine/install/linux-postinstall/

## az cli
```
curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash
```
