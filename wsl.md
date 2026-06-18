# wsl

## linux install XFCE
- https://wsl-ui.octasoft.co.uk/blog/wsl2-ubuntu-desktop-xrdp#step-1-install-your-desktop

## homebrew
```
sudo apt-get install build-essential procps curl file git -y

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

cd /home/linuxbrew/.linuxbrew/bin
./brew install ansible gh go-task -y
sudo apt install zsh ghostty alacritty -y

cd
git clone https://github.com/bradfordwagner/devtainer.git dotfiles

cd dotfiles
export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
task linux_brew_install && task bare_bones
```

## zap
```
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1
```

## swaywm
- https://github.com/bmo1177/sway_setup
- in ~/.config/sway/config - output X11-1 resolution 2496x1644 position 2496,0 scale 1.8
- cheatsheet - https://wiki.garudalinux.org/en/sway-cheatsheet
