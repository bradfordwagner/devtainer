# wsl

## linux install XFCE
- https://wsl-ui.octasoft.co.uk/blog/wsl2-ubuntu-desktop-xrdp#step-1-install-your-desktop

```
sudo apt update
sudo apt install xfce4 xfce4-goodies xrdp xclip -y
sudo sed -i 's/^port=3389/port=3390/' /etc/xrdp/xrdp.ini
printf '#!/bin/sh\nstartxfce4\n' > ~/.xsession && chmod +x ~/.xsession
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

## homebrew
```
sudo apt update && sudo apt upgrade -y
sudo apt-get install build-essential procps curl file git -y
sudo apt install zsh ghostty alacritty firefox -y
chsh -s /usr/bin/zsh
sudo apt install sway swaybg swayidle swaylock foot rofi -y

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
- XFCE - app finder -> session and startup -> current session
  - disable: xfwm4,xfce-panel,xfce4-power-manager
  - add sway to startup

## fonts
```
mkdir -p ~/.local/share/fonts && curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/IosevkaTerm.zip" -o /tmp/IosevkaTerm.zip && unzip -o /tmp/IosevkaTerm.zip -d ~/.local/share/fonts/IosevkaTerm && fc-cache -fv
```

## docker
- https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
- post install: https://docs.docker.com/engine/install/linux-postinstall/
