# wsl

## linux install XFCE
- https://wsl-ui.octasoft.co.uk/blog/wsl2-ubuntu-desktop-xrdp#step-1-install-your-desktop

## homebrew
```
sudo apt update && sudo apt upgrade -y
sudo apt-get install build-essential procps curl file git -y
sudo apt install zsh ghostty alacritty firefox -y
chsh -s /usr/bin/zsh
sudo apt install sway swaybg swayidle swaylock foot -y

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
cd /home/linuxbrew/.linuxbrew/bin
./brew install ansible gh go-task -y

# zap
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1

cd && git clone https://github.com/bradfordwagner/devtainer.git dotfiles && cd dotfiles
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
task linux_brew_install && task bare_bones

# xrdp - ensure .xsession uses sh shebang so changing login shell doesn't break the UI session
printf '#!/bin/sh\nstartxfce4\n' > ~/.xsession && chmod +x ~/.xsession
```

## swaywm
- https://github.com/bmo1177/sway_setup
- cheatsheet - https://wiki.garudalinux.org/en/sway-cheatsheet
- XFCE - app finder -> session and startup -> current session
  - disable: xfwm4,xfce-panel
  - add sway to startup
