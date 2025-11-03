################################################
# git aliases
################################################
function lazygit() {
    git add --all
    echo provide a commit message
    read commit_msg
    git commit -a -m "$commit_msg"
    git push
}
function lazyGitCommit() {
  local msg=$1
  git add .
  git commit -m "$msg"
}
# lazy git select
function lgs() {
  files=$(git status -s | awk '{print $2}' | fzf -m --preview="git diff {} | delta") || return
  echo $files | xargs -I {} git add {}
  echo provide a commit message
  read commit_msg
  git commit -m "${commit_msg}"
  git push
}
function git_restore() {
  git status -s | awk '{print $2}' | fzf -m --preview="git diff {} | delta" | xargs -I {} git restore {}
}
alias g=git
alias ga='git add'
alias gb='git branch'
alias gcb='git rev-parse --abbrev-ref HEAD'
alias gc='git clean -fd'
alias gcm='git commit -m'
alias gd='git diff'
alias glh="git ll | nl -v1 | sed 's/^ \+/&HEAD~/' | head -n 25" # git log head
alias glt='git log --tags --oneline --simplify-by-decoration --date-order --date=short --expand-tabs --color=always --no-walk --reverse --pretty=format:"%Cblue%ad (%cr)|%Cred%ae|%Cgreen%D%n" | column -t -s "|"'
alias gp='git push'
alias gpf='git push -f'    # git push force
alias gr=git_restore
alias grd='cd $(git root)' # git root directory
alias grh='git reset --hard' # git reset hard
alias grv='git remote -v'
alias gs='git status -s'
alias gss='git switch'
alias gsd='clear; gs; gd'
alias lg=lazygit
alias lgc=lazyGitCommit;
function gsl() {
  echo "${palette_lcyan}Git Status List - Checking directories...${palette_restore}\n"

  for dir in */; do
    if [[ -d "$dir" && -d "$dir/.git" ]]; then
      cd "$dir"
      git_status=$(git status --porcelain 2>/dev/null)
      branch=$(git branch --show-current 2>/dev/null)

      if [[ -n "$git_status" ]]; then
        # Dirty repo
        echo "${palette_lred}📁 $dir ${palette_lyellow}[$branch]${palette_lred} - DIRTY${palette_restore}"
        echo "$git_status" | head -3 | sed 's/^/  /'
      else
        # Clean repo
        echo "${palette_lgreen}📁 $dir ${palette_lyellow}[$branch]${palette_lgreen} - CLEAN${palette_restore}"
      fi
      cd ..
      echo
    elif [[ -d "$dir" ]]; then
      # Not a git repo
      echo "${palette_lgray}📁 $dir - Not a git repository${palette_restore}"
      echo
    fi
  done

  echo "${palette_lcyan}Summary complete.${palette_restore}"
}
function git_tag() {
  tag=${1}
  if [ -z "$tag" ]; then
    echo ${palette_lcyan}Latest Tags:${palette_restore}
    git tag -l | sort -V | tail -n 5 | sort -V
    # git sv: https://github.com/bvieira/sv4git
    echo -n "${palette_lcyan}current_version = " && git sv cv
    echo -n "${palette_lgreen}next_version =  " && git sv nv

    # breaking change
    items=(
      yes
      manual
    )
    use_next_version=$(printf "%s\n" "${items[@]}" \
     | fzf --exit-0 --height=4 --prompt="use next_version? "
    )
    if [[ "${use_next_version}" == "yes" ]]; then
      tag=$(git sv nv)
    else
      echo -n "tag: "
      read tag
    fi

    if [ -z "$tag" ]; then
      echo "No tag provided"
      return
    fi

    echo tag=${tag}
    echo ${tag} | pbcopy
  fi
  git tag ${tag}
  git push origin --tags
}
alias gt='git tag'
################################################################
# git sparse-checkout
################################################################
# Helper function to display sparse-checkout patterns with proper indentation
function _gsc_show_patterns() {
  local patterns
  patterns=$(git sparse-checkout list 2>/dev/null)
  if [[ -n "$patterns" ]]; then
    echo "$patterns" | sed 's/^/  /'
  else
    echo "  (disabled)"
  fi
}
# git sparse-checkout select - interactively select directories to add to sparse-checkout
function gscs() {
  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  # Get all directories from the git tree
  local dirs
  dirs=$(git ls-tree -r -d --name-only HEAD | sort)
  
  if [[ -z "$dirs" ]]; then
    echo "No directories found in repository"
    return 1
  fi

  # Let user select directories with fzf (multi-select enabled)
  local selected
  selected=$(echo "$dirs" | fzf -m --prompt="Select directories for sparse-checkout (Tab for multi-select): " --preview="echo {}") || return

  if [[ -z "$selected" ]]; then
    echo "No directories selected"
    return 1
  fi

  # Convert newlines to space-separated list for display
  local dirs_list=$(echo "$selected" | tr '\n' ' ')
  echo "Adding directories to sparse-checkout:"
  echo "$selected" | sed 's/^/  /'
  
  # Add selected directories to sparse-checkout
  echo "$selected" | xargs git sparse-checkout add
  
  echo "\nSparse-checkout updated. Current patterns:"
  _gsc_show_patterns
}
# git sparse-checkout set - interactively select directories to SET (replace) sparse-checkout
function gscset() {
  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  # Get all directories from the git tree
  local dirs
  dirs=$(git ls-tree -r -d --name-only HEAD | sort)
  
  if [[ -z "$dirs" ]]; then
    echo "No directories found in repository"
    return 1
  fi

  # Let user select directories with fzf (multi-select enabled)
  local selected
  selected=$(echo "$dirs" | fzf -m --prompt="Select directories for sparse-checkout SET (Tab for multi-select): " --preview="echo {}") || return

  if [[ -z "$selected" ]]; then
    echo "No directories selected"
    return 1
  fi

  echo "Setting sparse-checkout to:"
  echo "$selected" | sed 's/^/  /'
  
  # Set sparse-checkout to selected directories (replaces existing patterns)
  echo "$selected" | xargs git sparse-checkout set
  
  echo "\nSparse-checkout set. Current patterns:"
  _gsc_show_patterns
}
# git sparse-checkout remove - interactively remove directories from sparse-checkout
function gscr() {
  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  # Get current sparse-checkout patterns
  local current_patterns
  current_patterns=$(git sparse-checkout list 2>/dev/null)
  
  if [[ -z "$current_patterns" ]]; then
    echo "No sparse-checkout patterns currently set"
    return 1
  fi

  # Let user select patterns to remove with fzf (multi-select enabled)
  local to_remove
  to_remove=$(echo "$current_patterns" | fzf -m --prompt="Select directories to REMOVE from sparse-checkout (Tab for multi-select): " --preview="echo {}") || return

  if [[ -z "$to_remove" ]]; then
    echo "No directories selected for removal"
    return 1
  fi

  echo "Removing directories from sparse-checkout:"
  echo "$to_remove" | sed 's/^/  /'
  
  # Calculate remaining patterns (all current minus selected)
  local remaining
  remaining=$(comm -23 <(echo "$current_patterns" | sort) <(echo "$to_remove" | sort))
  
  if [[ -z "$remaining" ]]; then
    echo "\nWarning: This would remove all patterns. Disabling sparse-checkout instead."
    git sparse-checkout disable
  else
    echo "\nUpdating sparse-checkout to remaining directories:"
    echo "$remaining" | sed 's/^/  /'
    echo "$remaining" | xargs git sparse-checkout set
  fi
  
  echo "\nSparse-checkout updated. Current patterns:"
  _gsc_show_patterns
}
# git sparse-checkout list - show current sparse-checkout configuration
function gscl() {
  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  echo "Current sparse-checkout patterns:"
  _gsc_show_patterns
}
# git sparse-checkout menu - select action to perform
function gsc() {
  # Check if we're in a git repo
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi

  local actions=(
    "list|List current sparse-checkout patterns"
    "add|Add directories to current sparse-checkout"
    "replace|Replace all sparse-checkout patterns"
    "remove|Remove directories from sparse-checkout"
  )

  local selected
  selected=$(printf "%s\n" "${actions[@]}" | awk -F'|' '{printf "%-10s - %s\n", $1, $2}' | fzf --prompt="Select sparse-checkout action: " --height=7) || return

  local action=$(echo "$selected" | awk '{print $1}')

  case "$action" in
    list) gscl ;;
    add) gscs ;;
    replace) gscset ;;
    remove) gscr ;;
    *) echo "Unknown action: $action"; return 1 ;;
  esac
}
################################################################
