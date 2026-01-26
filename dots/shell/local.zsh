################################################
# mac specific
################################################
function setBackground() {
    local backgroundPath=$(realpath $1)
    osascript -e 'tell application "System Events" to tell every desktop to set picture to "'${backgroundPath}'"'
}
function mac_kill_all_apps() {
  osascript -e '-- get list of open apps
tell application "System Events"
  set allApps to displayed name of (every process whose background only is false) as list
end tell

-- leave some apps open
set exclusions to {"Finder", "LaunchBar"}

-- quit each app
repeat with thisApp in allApps
  set thisApp to thisApp as text
  if thisApp is not in exclusions then
    tell application thisApp to quit
  end if
end repeat'
}
################################################

