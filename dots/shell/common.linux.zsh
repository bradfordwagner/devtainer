# XQuartz / xrdp - detect active display, fallback to :0
export DISPLAY=$(ls /tmp/.X11-unix/ 2>/dev/null | head -1 | tr -d 'X' | sed 's/^/:/' || echo ':0')

# xdg-open uses rundll32 to open URLs in Windows; fixes git-open
export BROWSER=xdg-open

export PATH=$PATH:/snap/bin
[ -d /home/linuxbrew/.linuxbrew/bin ] && export PATH=/home/linuxbrew/.linuxbrew/bin:${PATH}
