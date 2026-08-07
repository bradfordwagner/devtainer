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

Inside the workspace (`coder ssh bwagner`), run the whole setup with one command. It fetches
[`coder-setup.sh`](coder-setup.sh) from GitHub and runs it — including the interactive
`sudo passwd coder` step (which reads the new password twice):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bradfordwagner/devtainer/main/coder-setup.sh)
```

> [!NOTE]
> It has to be `bash <(curl …)` (process substitution), **not** `curl … | bash`: a pipe feeds
> the script in on stdin, leaving `sudo passwd coder` (and rofi's `setup.sh`) with no terminal
> to read from. Process substitution passes the script as a file argument and keeps the tty
> attached, so the interactive prompts still work.

What the script does, in order (the script's own comments carry the full why for each step):

- **`passwd coder`** — sets the login password (interactive).
- **desktop packages** — xrdp/Xorg + the full sway userland (waybar, swaybg, rofi, fonts,
  grim/slurp, etc.). Without the userland you get a black screen even though sway launches fine.
  sway comes up at the small resolution pinned in `dots/config/sway/config`; bump it after
  connecting via `dots/shell_scripts/speed/sway_select_display.sh`.
- **`chsh` to zsh** — `/etc/passwd` is on the wiped layer, so this re-runs per rebuild.
- **xrdp on 3390** + the **`SessionSockdirGroup=xrdp` fix** — the real fix for the 30s
  "Error connecting to user session": sesman defaults the per-session socket dir to group
  `root`, which the group-`xrdp` front-end can't enter.
- **`~/.xsession`** with the **`XDG_RUNTIME_DIR` guard** — without it sway aborts
  ("XDG_RUNTIME_DIR is not set") and the RDP window opens then instantly closes; the pod has no
  systemd to create `/run/user/<uid>`. `task bb` renders the same guard via
  `templates/xsession.j2`.
- **clean xrdp (re)start** — via `service` (no systemd); kills orphans and clears the stale
  sesman pid + sockets that make `service xrdp restart` unreliable here.
- **firefox** — the real Mozilla `.deb` (pinned), not Ubuntu's snap stub (which needs
  snapd → systemd).
- **rofi theming + nerd font** — populate `~/.config/rofi` and `~/.local/share/fonts` on the
  persistent `~/`, so these are one-time (not per-rebuild).
- **homebrew** — symlinks the blessed prefix onto the PV (see below), installs brew
  (`NONINTERACTIVE=1`) + zap, then clones dotfiles and runs `task`.

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

### screenshots and the 64M `/dev/shm`

Kubernetes gives a pod a 64M `/dev/shm` by default. sway runs on its X11 backend here, and its
output buffers for a 3440x1440 screen already pin ~60M of that, so `grim` cannot get the ~20M
wl_shm pool it needs for a frame: it faults on write and dies with **SIGBUS (exit 135)**,
silently, leaving a 0-byte file. `grim -g` and `grim -s` don't help — wlr-screencopy always
hands over a full-size frame. `/dev/shm` also can't be remounted larger from inside the pod
(no `CAP_SYS_ADMIN`), and `df` will show the space as used with `ls /dev/shm` empty, because
the buffers are unlinked-but-mapped.

`dots/shell_scripts/screenshot.sh` works around this by falling back to `xwd` against the outer
xrdp Xorg that sway is nested inside — the same pixels, read with `XGetImage` over the X socket,
which never touches `/dev/shm`. It finds that display from sway's own `DISPLAY` (Xwayland's
`DISPLAY`, which we would otherwise inherit, points at the wrong screen) and converts with
netpbm, since brew's imagemagick is built without X11 and has no xwd decoder.

The proper fix is to give the pod a bigger `/dev/shm` in the workspace template — an
`emptyDir` with `medium: Memory` and a `sizeLimit` of 1Gi or so, mounted at `/dev/shm`. Once
that's in place `grim` takes over again on its own and the fallback goes unused.

## homebrew (persistent across rebuilds)

Homebrew's default prefix `/home/linuxbrew/.linuxbrew` lands on the pod's throwaway layer, so
a plain install vanishes on every rebuild. Homebrew only ships pre-built bottles for that one
blessed prefix, though — installing to a custom prefix like `~/homebrew` forces every formula
to build from source. So instead of moving the prefix, keep the prefix string and symlink its
storage onto the persistent home volume: bottles still work, and the installed formulae
persist. Only the (cheap) symlink lives on the overlay and needs re-creating after a rebuild.

The commands for this — the `~/linuxbrew` symlink, the brew install (run with `NONINTERACTIVE=1`),
zap, the dotfiles clone, and `task` — run as part of the combined first-time-setup paste block
above, so there's nothing extra to paste here.

`brew --prefix` still reports `/home/linuxbrew/.linuxbrew`, so bottles are used as normal and
`dots/shell/common.linux.zsh` (which hardcodes that prefix on PATH) needs no change.

The manual `sudo ln -sfn` above is only needed for the **first** install (to bootstrap brew →
go-task/ansible before dotfiles exist). After that, `task bb` re-creates the symlink itself:
`tasks/linux-specific.yml` ensures `~/linuxbrew` and, when it can sudo, relinks
`/home/linuxbrew/.linuxbrew` → `~/linuxbrew` (skipped safely if a real brew dir already lives
there, as on WSL). So post-rebuild, once `~/` is back, `task bb` restores brew without a manual
step.
