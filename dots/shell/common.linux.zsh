# XQuartz / xrdp - detect active display, fallback to :0
export DISPLAY=$(ls /tmp/.X11-unix/ 2>/dev/null | head -1 | tr -d 'X' | sed 's/^/:/' || echo ':0')

# xdg-open uses rundll32 to open URLs in Windows; fixes git-open
export BROWSER=xdg-open

export PATH=$PATH:/snap/bin
[ -d /home/linuxbrew/.linuxbrew/bin ] && export PATH=/home/linuxbrew/.linuxbrew/bin:${PATH}

# WSL: shim wl-paste so Claude Code's image-paste falls through to PowerShell.
# WSLg only offers Windows-copied images as 32bpp BI_BITFIELDS BMP, which
# libvips cannot decode; the shim fails image/* reads so Claude's fallback
# chain reaches its PowerShell branch, which returns a real PNG.
# See dots/shell_scripts/wsl-shims/wl-paste.
if [ -n "${WSL_DISTRO_NAME}${WSL_INTEROP}" ] && [ -d ~/.dotfiles/dots/shell_scripts/wsl-shims ]; then
  export PATH=~/.dotfiles/dots/shell_scripts/wsl-shims:${PATH}
fi
