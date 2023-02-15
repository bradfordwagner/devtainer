
xset r rate 175 25 # keyboard: set a fast repeat with little delay
# picom &
#sudo systemctl restart vmtoolsd.service # this is required for vmware fusion+manjaro - sets resolution automatically
unclutter-xfixes --timeout 3 &
sleep 3; nitrogen --restore             # set desktop background
