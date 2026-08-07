# coder

Working notes for a Coder Kubernetes workspace (`BradfordWagner/bwagner`). The pod is bare —
no systemd, no window manager — and its writable layer (`/`) is wiped on every rebuild, while
`~/` (`/home/coder`) is a persistent volume. Anything below that touches `/` needs re-running
after a rebuild (or baking into the base image); anything under `~/` survives.

## remote desktop (RDP)

RDP into an xrdp desktop running in the workspace. Same xrdp/Xorg stack as the WSL XFCE setup
in [wsl.md](wsl.md), but the pod is bare (no systemd, no window manager) and ships xrdp with a
broken default, so it needs the extra fixes below.

Forward the workspace's xrdp port (`3390`) to a local port, then point mstsc at it:

```bash
coder port-forward bwagner --tcp 5900:3390
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
# `service xrdp start` is enough; if you've already been fighting it, do a full clean start:
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
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
sudo apt-get update -qq
sudo apt-get install -y --allow-downgrades firefox
# verify it's the real thing (not the snap stub): `file /usr/bin/firefox` should be an ELF
# binary / symlink into /usr/lib/firefox, and `firefox --version` should print a version.
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

## homebrew (persistent across rebuilds)

Homebrew's default prefix `/home/linuxbrew/.linuxbrew` lands on the pod's throwaway layer, so
a plain install vanishes on every rebuild. Homebrew only ships pre-built bottles for that one
blessed prefix, though — installing to a custom prefix like `~/homebrew` forces every formula
to build from source. So instead of moving the prefix, keep the prefix string and symlink its
storage onto the persistent home volume: bottles still work, and the installed formulae
persist. Only the (cheap) symlink lives on the overlay and needs re-creating after a rebuild.

```bash
# real store lives in the persistent home volume (~/ = /home/coder, an ext4 PV)
mkdir -p ~/linuxbrew
# re-create this one symlink after each rebuild — it's the only part on the ephemeral layer
sudo mkdir -p /home/linuxbrew
sudo ln -sfn ~/linuxbrew /home/linuxbrew/.linuxbrew

# install brew normally — it writes into ~/linuxbrew via the symlink
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
brew install ansible gh go-task

# zap
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1

# clone dotfiles and bring the box up (~/ persists across rebuilds, so clone only if missing)
cd && { [ -d dotfiles/.git ] || git clone https://github.com/bradfordwagner/devtainer.git dotfiles; } && cd dotfiles
task linux_brew_install && task bare_bones
```

`brew --prefix` still reports `/home/linuxbrew/.linuxbrew`, so bottles are used as normal and
`dots/shell/common.linux.zsh` (which hardcodes that prefix on PATH) needs no change.

The manual `sudo ln -sfn` above is only needed for the **first** install (to bootstrap brew →
go-task/ansible before dotfiles exist). After that, `task bb` re-creates the symlink itself:
`tasks/linux-specific.yml` ensures `~/linuxbrew` and, when it can sudo, relinks
`/home/linuxbrew/.linuxbrew` → `~/linuxbrew` (skipped safely if a real brew dir already lives
there, as on WSL). So post-rebuild, once `~/` is back, `task bb` restores brew without a manual
step.
