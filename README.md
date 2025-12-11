# Devtainer
- Bradford's happy dotfiles, finally made public! Also as a container at https://quay.io/repository/bradfordwagner/devtainer?tab=tags it's a bit of a WIP so bear with me.

## Mac Quickstart
```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ansible gh go-task
gh auth login -w -p https

# install zap package manager
zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1

task sudoer
task

# still comes from the original dotfiles
ansible-playbook pb-kubectl-krew.yml

# vim
python3 -m pip install --user --upgrade pynvim

# download and install tkgi cli
# https://network.pivotal.io/products/pivotal-container-service/#/releases/1293578/file_groups/13745
```

## Help with Unknown Sources
```bash
sudo spctl --master-enable
sudo spctl --master-disable

# manually add it
xattr -d com.apple.quarantine /Applications/Alacritty.app
xattr -d com.apple.quarantine '/Applications/QMK Toolbox.app'
```

## Intellij Settings
- plugins: smart align, gruvbox, go, EasyChangeFontSize, Gitlab Integration, Hashicorp Terraform / HCL Language Support, IdeaVim, Kubernetes, Makefile Language, Nord, Python, Rainbow Brakets, Yaml / Ansible Support
```vm options
-Xms512m
-Xmx2g
-Deditor.distraction.free.mode=true
```
### idea external tools
```yaml
- name: open_file
  program: alacritty
  args: -e zsh -lc "ij_open_file $ProjectFileDir$ $FilePath$"
- name: search_file
  program: alacritty
  args: -e zsh -lc "ij_search_file $ProjectFileDir$ $FilePath$"
- name: search_files
  program: alacritty
  args: -e zsh -lc "ij_search $ProjectFileDir$ $FilePath$"
- name: terminal
  program: alacritty
  args: --working-directory $ProjectFileDir$ -e zsh -lc tn
- name: open_file_v2
  program: /bin/zsh
  args: -lc "ij_open_file_v2 $ProjectFileDir$"
# kubectl
- name: kubectl_apply
  program: kubecolor
  args: apply -f $FileRelativePath$
  working_directory: $ProjectFileDir$
- name: kubectl_delete
  program: kubecolor
  args: delete -f $FileRelativePath$
  working_directory: $ProjectFileDir$
```

## Intellij Theme
- Trash Panda (Blacklight)

## Install rofi themes
- install macports
    - work requires installing using - https://guide.macports.org/#installing.macports.git as rsync does not work
```bash
# only for work
# to get broken python tbz2
docker run --rm -it -v $(pwd):/host/ quay.io/bradfordwagner/rofi sh -c 'cp -v /tmp/* /host/'
sudo cp python313-3.13.2_0+lto+optimizations.darwin_24.arm64.tbz2 /opt/local/var/macports/incoming/verified/
sudo cp python313-3.13.2_0+lto+optimizations.darwin_24.arm64.tbz2.rmd160 /opt/local/var/macports/incoming/verified
# end only for work

cd /tmp
git clone https://github.com/adi1090x/rofi
cd rofi
./setup.sh
```

## Zen about:config
- [theme important settings](https://www.reddit.com/r/zen_browser/comments/1hbh50h/transparent_themessetting_for_macos/)
```
zen.tabs.dim-pending=false               # https://github.com/zen-browser/desktop/issues/225
zen.view.grey-out-inactive-windows=false # https://www.reddit.com/r/zen_browser/comments/1ikpc9i/is_it_possible_to_make_it_so_when_i_click_off_of/
```
