################################################
# mac specific
################################################
function setBackground() {
    local backgroundPath=$(realpath $1)
    osascript -e 'tell application "System Events" to tell every desktop to set picture to "'${backgroundPath}'"'
}
################################################

